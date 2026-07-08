#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

# 进入正确的编译环境
cd /home/build/openwrt || cd /home/build/immortalwrt || cd /

echo "当前编译目录: $(pwd)"

# 直接执行构建，并指定输出目录为我们挂载的 /home/build/custom/bin
# 注意：有些 ImageBuilder 版本不支持 BIN_DIR 参数，但大多数支持
make image \
  PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE \
  BIN_DIR="/home/build/custom/bin"

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功，固件已输出到 custom/bin 目录"
else
    echo "❌ 构建失败"
    exit 1
fi