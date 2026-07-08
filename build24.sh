#!/bin/bash
set -e

echo "🍞 构建: $TARGET_NAME | ${ROM_SIZE}MB"

# 加载包列表
source /home/build/custom/shell/custom-packages.sh

# 进入构建目录
cd /home/build/immortalwrt

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
rm -rf /tmp/firmware
mkdir -p /tmp/firmware
cp -r "$OUTPUT_DIR"/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || \
  sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成"
ls -lh /home/build/custom/output/ | tail -5