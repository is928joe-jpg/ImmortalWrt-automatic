#!/bin/bash

# --- 调试信息：查看当前容器环境 ---
echo "--- 调试信息 ---"
pwd
ls -F
echo "----------------"

# 导入插件列表
source shell/custom-packages.sh
echo "正在加载插件: $CUSTOM_PACKAGES"

# 尝试定位 Makefile，有些镜像可能在子目录
if [ -f "Makefile" ]; then
    echo "✅ 找到 Makefile，开始构建..."
elif [ -d "openwrt" ] && [ -f "openwrt/Makefile" ]; then
    echo "📂 切换到 openwrt 子目录进行构建..."
    cd openwrt
else
    echo "⚠️ 未找到 Makefile，尝试列出所有文件帮助排查："
    find . -maxdepth 2 -name "Makefile"
fi

# 执行构建
make image \
  PROFILE="generic" \
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