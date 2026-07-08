#!/bin/bash
set -e

echo "========================================="
echo "🍞 构建: $TARGET_ARCH | ${ROM_SIZE}MB"
echo "========================================="

# 加载配置
source /home/build/custom/shell/custom-packages.sh

# 应用 imm.config（替换而非追加，避免冲突）
if [ -f "/home/build/custom/$TARGET_ARCH/imm.config" ]; then
    cat /home/build/custom/$TARGET_ARCH/imm.config > /home/build/immortalwrt/.config
elif [ -f "/home/build/custom/files/imm.config" ]; then
    cat /home/build/custom/files/imm.config > /home/build/immortalwrt/.config
fi

# 进入构建目录
cd /home/build/immortalwrt

# 选择 Profile
case "$TARGET_ARCH" in
    "x86-64")
        PROFILE=""
        ;;
    "rockchip-armv8")
        PROFILE='PROFILE="friendlyarm_nanopi-r4s"'
        ;;
    "mediatek-filogic")
        PROFILE='PROFILE="xiaomi_ax6000"'
        ;;
    *)
        PROFILE=""
        ;;
esac

# 构建
echo "🍞 开始编译..."
if [ -n "$PROFILE" ]; then
    eval "make image $PROFILE PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/build.log
else
    make image PACKAGES="$CUSTOM_PACKAGES" FILES="/home/build/custom/files" ROOTFS_PARTSIZE=$ROM_SIZE 2>&1 | tee /tmp/build.log
fi

# 检查结果
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ 构建失败:"
    grep -iE "error|failed|cannot find|not found|Missing" /tmp/build.log | tail -5
    exit 1
fi

# 复制输出
OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
cp -r "$OUTPUT_DIR"/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || \
  sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成"
ls -lh /home/build/custom/output/ | tail -5