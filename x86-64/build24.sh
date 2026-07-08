#!/bin/bash
# 导入自定义插件列表
source /home/build/custom/shell/custom-packages.sh

echo "--- 调试：确认编译环境 ---"
# 自动寻找合法的编译根目录
if [ -d "/home/build/openwrt" ]; then
    cd /home/build/openwrt
elif [ -d "/home/build/immortalwrt" ]; then
    cd /home/build/immortalwrt
else
    cd /
fi

echo "当前编译目录: $(pwd)"
ls -F # 确认 Makefile 在这里
echo "--------------------------"

echo "正在加载插件: $CUSTOM_PACKAGES"

# 执行构建
make image \
  PROFILE="generic" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$PROFILE

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    # 将输出文件复制到 custom/bin 以便在宿主机获取
    mkdir -p /home/build/custom/bin
    cp -r bin/targets/x86/64/* /home/build/custom/bin/
else
    echo "❌ 构建失败"
    exit 1
fi