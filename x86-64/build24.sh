#!/bin/bash
set -e

echo "=== 步骤1: 加载自定义包列表 ==="
source /home/build/custom/shell/custom-packages.sh

echo "=== 步骤2: 进入 ImageBuilder 目录 ==="
BUILDER_DIR="/home/build/immortalwrt"
cd "$BUILDER_DIR" || {
    echo "❌ ImageBuilder 构建目录不存在 ($BUILDER_DIR)"
    exit 1
}

echo "当前用户: $(id)"
echo "当前目录: $(pwd)"
echo "目录内容:"
ls -la

echo "=== 步骤3: 修复文件权限 ==="
if [ -f ".profiles.mk" ]; then
    chmod 644 .profiles.mk 2>/dev/null || true
    echo ".profiles.mk 权限已修复"
fi
find . -name "*.mk" -type f -exec chmod 644 {} \; 2>/dev/null || true
find . -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
echo "权限修复完成"

echo "=== 步骤4: 查询可用 profiles ==="
make info
echo "=== profiles 查询完毕 ==="

echo "=== 步骤5: 选择设备 Profile ==="
case "$TARGET-$SUBTARGET" in
    "x86-64") 
        # 使用小写的 generic（从 make info 输出中可以看到是小写）
        DEVICE_PROFILE="generic"
        echo "x86-64 架构使用 Profile: generic"
        ;;
    "rockchip-armv8") 
        DEVICE_PROFILE="friendlyarm_nanopi-r4s"
        echo "rockchip-armv8 架构使用 Profile: friendlyarm_nanopi-r4s"
        ;;
    "mediatek-filogic") 
        DEVICE_PROFILE="xiaomi_ax6000"
        echo "mediatek-filogic 架构使用 Profile: xiaomi_ax6000"
        ;;
    *) 
        DEVICE_PROFILE="generic"
        echo "未知架构，使用默认 Profile: generic"
        ;;
esac

echo "最终选择 Profile: $DEVICE_PROFILE"
echo "目标: $TARGET/$SUBTARGET | Profile: $DEVICE_PROFILE | 固件大小: ${ROM_SIZE}MB"

echo "=== 步骤6: 开始构建固件 ==="
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

echo "=== 步骤7: 构建完成，复制固件文件 ==="
mkdir -p /home/build/custom/output

echo "查找构建输出目录..."
find "$BUILDER_DIR" -type d -path "*/bin/targets/*" 2>/dev/null || echo "未找到 bin/targets 目录"

if [ -d "$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET" ]; then
    echo "找到输出目录: $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
    echo "输出目录内容:"
    ls -la "$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET/"
    echo "开始复制文件..."
    cp -rv "$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET/"* /home/build/custom/output/
else
    echo "❌ 未找到构建输出目录: $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
    echo "搜索所有 bin 目录..."
    find "$BUILDER_DIR" -type d -name "bin" 2>/dev/null
    exit 1
fi

echo "=== 步骤8: 显示输出文件 ==="
ls -lh /home/build/custom/output/
echo "=== 构建脚本执行完毕 ==="