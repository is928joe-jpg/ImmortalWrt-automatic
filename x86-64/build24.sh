#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

# 进入编译环境
cd /home/build/openwrt || cd /home/build/immortalwrt || cd /

echo "正在执行构建..."

make image \
  PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    mkdir -p /home/build/custom/output
    cp -r /home/build/openwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null || \
    cp -r /home/build/immortalwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null
    echo "构建产物："
    ls -la /home/build/custom/output/
else
    echo "❌ 构建失败"
    exit 1
fi