#!/bin/bash
set -e

source /home/build/custom/shell/custom-packages.sh
cd /home/build/immortalwrt

echo "🍞 编译: $PROFILE | ${ROM_SIZE}MB"
eval "make image $PROFILE PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/build.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 失败:" && grep -iE "error|failed|not found" /tmp/build.log | tail -3
    exit 1
fi

rm -rf /tmp/firmware && mkdir -p /tmp/firmware
cp -r bin/targets/$TARGET/$SUBTARGET/* /tmp/firmware/
mkdir -p /home/build/custom/output
cp -r /tmp/firmware/* /home/build/custom/output/ 2>/dev/null || sudo cp -r /tmp/firmware/* /home/build/custom/output/

echo "✅ 完成" && ls -lh /home/build/custom/output/ | tail -3