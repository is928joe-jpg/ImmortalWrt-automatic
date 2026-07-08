#!/bin/bash

# 1. 加载配置（如果存在）
if [ -f "/home/build/custom/shell/custom-packages.sh" ]; then
    source /home/build/custom/shell/custom-packages.sh
else
    CUSTOM_PACKAGES="luci luci-base luci-nginx luci-theme-bootstrap"
fi

# 2. 确定构建目录
cd /home/build/openwrt || cd /home/build/immortalwrt || {
    echo "❌ 无法进入编译目录"
    exit 1
}

# 3. 智能映射 PROFILE（根据架构选择）
case "$TARGET-$SUBTARGET" in
    "x86-64") DEVICE_PROFILE="generic" ;;
    "rockchip-armv8") DEVICE_PROFILE="friendlyarm_nanopi-r4s" ;;
    "mediatek-filogic") DEVICE_PROFILE="xiaomi_ax6000" ;;
    *) DEVICE_PROFILE="generic" ;;
esac

echo "=========================================="
echo "构建信息"
echo "=========================================="
echo "目标: $TARGET/$SUBTARGET"
echo "设备: $DEVICE_PROFILE"
echo "版本: $VERSION"
echo "固件大小: ${ROM_SIZE}MB"
echo "当前目录: $(pwd)"
echo "=========================================="

# 4. 执行构建
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

# 5. 检查结果并移动产物
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    
    # 确定源目录
    if [ -d "/home/build/openwrt/bin/targets/$TARGET/$SUBTARGET" ]; then
        SOURCE_DIR="/home/build/openwrt/bin/targets/$TARGET/$SUBTARGET"
    elif [ -d "/home/build/immortalwrt/bin/targets/$TARGET/$SUBTARGET" ]; then
        SOURCE_DIR="/home/build/immortalwrt/bin/targets/$TARGET/$SUBTARGET"
    else
        echo "❌ 未找到构建产物目录"
        exit 1
    fi
    
    echo "源目录: $SOURCE_DIR"
    
    # 复制产物到挂载目录
    mkdir -p /home/build/custom/output
    cp -rv $SOURCE_DIR/* /home/build/custom/output/
    chmod -R 755 /home/build/custom/output
    
    echo ""
    echo "✅ 构建产物："
    ls -lh /home/build/custom/output/
    
    FILE_COUNT=$(ls -1 /home/build/custom/output/ 2>/dev/null | wc -l)
    echo "总共 $FILE_COUNT 个文件"
    
    if [ $FILE_COUNT -eq 0 ]; then
        echo "❌ 错误：没有找到任何构建产物"
        exit 1
    fi
else
    echo "❌ 构建失败"
    exit 1
fi

echo "🎉 构建流程完成"