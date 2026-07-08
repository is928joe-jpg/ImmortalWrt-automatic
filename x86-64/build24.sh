#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

# 进入正确的编译环境
cd /home/build/openwrt || cd /home/build/immortalwrt || cd /

echo "正在执行构建..."

# 不再指定 BIN_DIR，使用 ImageBuilder 默认的输出路径
make image \
  PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
else
    echo "❌ 构建失败"
    exit 1
fi