#!/bin/bash
set -e

echo "🍞 构建: $TARGET_ARCH | ${ROM_SIZE}MB"

source /home/build/custom/shell/custom-packages.sh
cd /home/build/immortalwrt

# 如果用户指定了 DEVICE 且不是 generic，用指定的
if [ -n "$DEVICE" ] && [ "$DEVICE" != "generic" ]; then
    PROFILE="PROFILE=\"$DEVICE\""
else
    # 自动从 make info 取第一个设备
    FIRST=$(make info 2>/dev/null | grep -v "Available Profiles\|Current\|Default\|^\s*$" | head -1 | awk '{print $1}' | sed 's/:$//')
    if [ -n "$FIRST" ]; then
        PROFILE="PROFILE=\"$FIRST\""
        echo "🍞 自动选择: $FIRST"
    else
        PROFILE=""
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