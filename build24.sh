#!/bin/bash
set -e

echo "🍞 构建: $TARGET_ARCH | ${ROM_SIZE}MB"

source /home/build/custom/shell/custom-packages.sh
cd /home/build/immortalwrt

if [ -n "$DEVICE" ]; then
    PROFILE="PROFILE=\"$DEVICE\""
    echo "🍞 指定设备: $DEVICE"
elif [ "$TARGET_ARCH" = "x86-64" ]; then
    PROFILE=""
    echo "🍞 x86-64 默认配置"
else
    echo "🍞 自动检测设备..."
    INFO=$(make info 2>/dev/null)
    echo "$INFO"
    echo "---"
    # 提取 Available Profiles 之后第一个非空非标题行
    PROFILE_NAME=$(echo "$INFO" | sed -n '/Available Profiles/,$p' | grep -v "Available Profiles\|Current\|Default\|^\s*$" | head -1 | awk '{print $1}' | sed 's/:$//')
    if [ -n "$PROFILE_NAME" ]; then
        PROFILE="PROFILE=\"$PROFILE_NAME\""
        echo "🍞 选择: $PROFILE_NAME"
    else
        PROFILE=""
        echo "🍞 未检测到，使用默认"
    fi
fi

echo "🍞 开始编译..."
if [ -n "$PROFILE" ]; then
    eval "make image $PROFILE PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/build.log
else
    make image PACKAGES="$CUSTOM_PACKAGES" FILES="/home/build/custom/files" ROOTFS_PARTSIZE=$ROM_SIZE 2>&1 | tee /tmp/build.log
fi

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 失败:"
    grep -iE "error|failed|not found|does not exist" /tmp/build.log | tail -5
    exit 1
fi

OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
rm -rf /tmp/firmware && mkdir -p /tmp/firmware
cp -r "$OUTPUT_DIR"/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成"
ls -lh /home/build/custom/output/ | tail -5