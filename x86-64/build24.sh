#!/bin/bash
set -e

# 加载你的自定义包列表
source /home/build/custom/shell/custom-packages.sh

# ImageBuilder 的真实工作目录
cd /builder || {
    echo "❌ ImageBuilder 构建目录不存在 (/builder)"
    exit 1
}

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
cp -rv /builder/bin/targets/$TARGET/$SUBTARGET/* /home/build/custom/output/
chmod -R 755 /home/build/custom/output
ls -lh /home/build/custom/output/
