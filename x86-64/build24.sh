#!/bin/bash
# 导入你的插件列表
source shell/custom-packages.sh

echo "正在加载插件: $CUSTOM_PACKAGES"

# 执行构建 (核心命令)
# $PROFILE 由 YAML 传入，决定镜像大小
# $CUSTOM_PACKAGES 从上面导入
make image PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/immortalwrt/files" \
  ROOTFS_PARTSIZE=$PROFILE

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
else
    echo "❌ 构建失败"
    exit 1
fi