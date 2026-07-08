#!/bin/bash
set -e

source /home/build/custom/shell/custom-packages.sh
cd /home/build/immortalwrt

echo "🍞 可用 profiles:"
make info 2>/dev/null | tail -30

echo "🍞 编译: $PROFILE | ${ROM_SIZE}MB"
if [ -n "$PROFILE" ]; then
    eval "make image $PROFILE PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/build.log
else
    make image PACKAGES="$CUSTOM_PACKAGES" FILES="/home/build/custom/files" ROOTFS_PARTSIZE=$ROM_SIZE 2>&1 | tee /tmp/build.log
fi

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 失败:" && grep -iE "error|failed|not found|does not exist" /tmp/build.log | tail -5
    exit 1
fi

rm -rf /tmp/firmware && mkdir -p /tmp/firmware
cp -r bin/targets/$TARGET/$SUBTARGET/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成" && ls -lh /home/build/custom/output/ | tail -3