#!/bin/bash
set -e

# 加载你的自定义包列表
source /home/build/custom/shell/custom-packages.sh

# 探测 ImageBuilder 的真实工作目录
if [ -d "/builder" ]; then
    BUILDER_DIR="/builder"
elif [ -d "/home/build" ] && [ -f "/home/build/Makefile" ]; then
    BUILDER_DIR="/home/build"
else
    # 自动查找包含 Makefile 且包含 'image' 目标的目录
    BUILDER_DIR=$(find / -maxdepth 3 -name "Makefile" -path "*/target/linux" 2>/dev/null | head -1 | xargs dirname | xargs dirname | xargs dirname 2>/dev/null || echo "")
    
    if [ -z "$BUILDER_DIR" ]; then
        # 尝试查找 ImageBuilder 的特征文件
        BUILDER_DIR=$(find / -maxdepth 4 -name ".config" -o -name "repositories.conf" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")
    fi
    
    if [ -z "$BUILDER_DIR" ] || [ ! -d "$BUILDER_DIR" ]; then
        echo "❌ 无法找到 ImageBuilder 构建目录"
        echo "目录结构:"
        ls -la /
        echo "尝试查找 Makefile:"
        find / -name "Makefile" -maxdepth 3 2>/dev/null
        exit 1
    fi
fi

echo "ImageBuilder 目录: $BUILDER_DIR"
cd "$BUILDER_DIR" || {
    echo "❌ 无法进入目录: $BUILDER_DIR"
    exit 1
}

# 列出当前目录内容以确认
echo "当前目录内容:"
ls -la

# 选择设备 Profile
case "$TARGET-$SUBTARGET" in
    "x86-64") DEVICE_PROFILE="generic" ;;
    "rockchip-armv8") DEVICE_PROFILE="friendlyarm_nanopi-r4s" ;;
    "mediatek-filogic") DEVICE_PROFILE="xiaomi_ax6000" ;;
    *) DEVICE_PROFILE="generic" ;;
esac

echo "目标: $TARGET/$SUBTARGET | Profile: $DEVICE_PROFILE | 固件大小: ${ROM_SIZE}MB"

# 构建固件
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

# 输出固件
mkdir -p /home/build/custom/output
cp -rv $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET/* /home/build/custom/output/
chmod -R 755 /home/build/custom/output
ls -lh /home/build/custom/output/