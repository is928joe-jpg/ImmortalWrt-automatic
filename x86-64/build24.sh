#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

cd /home/build/openwrt || cd /home/build/immortalwrt || cd /

echo "正在执行构建..."
echo "固件大小: ${PROFILE}MB"

make image \
  PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    mkdir -p /home/build/custom/output
    cp -r /home/build/openwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null || \
    cp -r /home/build/immortalwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null
    chmod -R 755 /home/build/custom/output
    echo "构建产物："
    ls -la /home/build/custom/output/
else
    echo "❌ 构建失败"
    exit 1
fi