#!/bin/bash
# 假设 custom-packages.sh 中定义了 $CUSTOM_PACKAGES
source /home/build/custom/shell/custom-packages.sh

# 1. 设备 PROFILE 映射表
# 请根据实际设备名称修改下面的 case 匹配项
case "${TARGET}-${SUBTARGET}" in
    "x86-64")
        DEVICE_PROFILE="generic"
        ;;
    "rockchip-armv8")
        # 示例：如果是 R4S
        DEVICE_PROFILE="friendlyarm_nanopi-r4s"
        ;;
    "mediatek-filogic")
        # 示例：如果是小米 AX6000
        DEVICE_PROFILE="xiaomi_ax6000"
        ;;
    *)
        echo "未知的架构: ${TARGET}-${SUBTARGET}，默认使用 generic"
        DEVICE_PROFILE="generic"
        ;;
esac

echo "正在构建: ${TARGET}/${SUBTARGET}"
echo "使用的 PROFILE: ${DEVICE_PROFILE}"

# 2. 执行构建
# 注意：imagebuilder 容器内通常不需要 cd，直接 make 即可
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

# 3. 处理产物
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    mkdir -p /home/build/custom/output
    # 动态路径复制
    cp -r bin/targets/${TARGET}/${SUBTARGET}/* /home/build/custom/output/ 2>/dev/null
    chmod -R 755 /home/build/custom/output
else
    echo "❌ 构建失败"
    exit 1
fi