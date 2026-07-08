#!/bin/bash

# 加载自定义包列表
source /home/build/custom/ImmortalWrt/shell/custom-packages.sh

# ImageBuilder 默认构建目录永远是 /home/build/openwrt
cd /home/build/openwrt || {
    echo "❌ ImageBuilder 构建目录不存在"
    exit 1
}

# 设备 Profile 映射
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
  FILES="/home/build/custom/ImmortalWrt/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"

    mkdir -p /home/build/custom/output

    # 固件产物路径固定为 /home/build/openwrt/bin/targets
    cp -rv /home/build/openwrt/bin/targets/$TARGET/$SUBTARGET/* /home/build/custom/output/

    chmod -R 755 /home/build/custom/output
    ls -lh /home/build/custom/output/
else
    echo "❌ 构建失败"
    exit 1
fi
