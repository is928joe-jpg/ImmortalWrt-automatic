#!/bin/bash

source /home/build/custom/ImmortalWrt/shell/custom-packages.sh

# ImageBuilder 默认构建目录
cd /home/build/openwrt || {
    echo "❌ ImageBuilder 构建目录不存在"
    exit 1
}

case "$TARGET-$SUBTARGET" in
    "x86-64") DEVICE_PROFILE="generic" ;;
    "rockchip-armv8") DEVICE_PROFILE="friendlyarm_nanopi-r4s" ;;
    "mediatek-filogic") DEVICE_PROFILE="xiaomi_ax6000" ;;
    *) DEVICE_PROFILE="generic" ;;
esac

echo "目标: $TARGET/$SUBTARGET | Profile: $DEVICE_PROFILE | 固件大小: ${ROM_SIZE}MB"

make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/ImmortalWrt/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"

    mkdir -p /home/build/custom/output
    cp -rv /home/build/openwrt/bin/targets/$TARGET/$SUBTARGET/* /home/build/custom/output/

    chmod -R 755 /home/build/custom/output
    ls -lh /home/build/custom/output/
else
    echo "❌ 构建失败"
    exit 1
fi
