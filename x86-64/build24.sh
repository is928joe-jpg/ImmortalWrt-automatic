#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

# 动态映射表：根据传入的架构定义设备名
case "${TARGET}-${SUBTARGET}" in
    "x86-64")
        DEVICE_PROFILE="generic" ;;
    "rockchip-armv8")
        DEVICE_PROFILE="friendlyarm_nanopi-r4s" ;; # 这里填入你常用的板子名
    "mediatek-filogic")
        DEVICE_PROFILE="xiaomi_ax6000" ;;
    "broadcom-bcm27xx")
        DEVICE_PROFILE="rpi-4" ;;
    *)
        echo "⚠️ 未在映射表中找到 ${TARGET}-${SUBTARGET}，尝试使用 generic..."
        DEVICE_PROFILE="generic"
        ;;
esac

echo "--- 开始构建 ---"
echo "架构: ${TARGET}/${SUBTARGET}"
echo "Profile: ${DEVICE_PROFILE}"

make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

if [ $? -eq 0 ]; then
    mkdir -p /home/build/custom/output
    cp -r bin/targets/${TARGET}/${SUBTARGET}/* /home/build/custom/output/
    echo "✅ 构建产物已保存"
else
    echo "❌ 构建失败"
    exit 1
fi