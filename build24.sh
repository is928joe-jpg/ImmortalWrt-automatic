#!/bin/bash
set -e

echo "🍞 构建: $TARGET_ARCH | ${ROM_SIZE}MB"

source /home/build/custom/shell/custom-packages.sh
cd /home/build/immortalwrt

# 选择 Profile
if [ -n "$DEVICE" ]; then
    PROFILE="PROFILE=\"$DEVICE\""
    echo "🍞 使用指定设备: $DEVICE"
elif [ "$TARGET_ARCH" = "x86-64" ]; then
    PROFILE=""
    echo "🍞 x86-64 使用默认配置"
else
    echo "🍞 自动检测设备..."
    PROFILE_NAME=$(make info 2>/dev/null | sed -n '/^[a-zA-Z0-9_-]\+:$/p' | head -1 | sed 's/:$//')
    if [ -n "$PROFILE_NAME" ]; then
        PROFILE="PROFILE=\"$PROFILE_NAME\""
        echo "🍞 自动选择: $PROFILE_NAME"
    else
        PROFILE=""
        echo "🍞 未检测到设备，使用默认"
    fi
fi

echo "🍞 开始编译..."
if [ -n "$PROFILE" ]; then
    eval "make image $PROFILE PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/build.log
else
    make image PACKAGES="$CUSTOM_PACKAGES" FILES="/home/build/custom/files" ROOTFS_PARTSIZE=$ROM_SIZE 2>&1 | tee /tmp/build.log
fi

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 构建失败:"
    grep -iE "error|failed|not found|Missing" /tmp/build.log | tail -5
    exit 1
fi

OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
rm -rf /tmp/firmware && mkdir -p /tmp/firmware
cp -r "$OUTPUT_DIR"/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成"
ls -lh /home/build/custom/output/ | tail -5