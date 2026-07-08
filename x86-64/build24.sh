#!/bin/bash
set -e

# 加载你的自定义包列表
source /home/build/custom/shell/custom-packages.sh

# ImageBuilder 的工作目录（根据上次成功的日志，实际在 /home/build/immortalwrt）
BUILDER_DIR="/home/build/immortalwrt"
cd "$BUILDER_DIR" || {
    echo "❌ ImageBuilder 构建目录不存在 ($BUILDER_DIR)"
    exit 1
}

echo "当前用户: $(id)"
echo "当前目录: $(pwd)"

# 修复 .profiles.mk 权限问题
echo "修复关键文件权限..."
if [ -f ".profiles.mk" ]; then
    chmod 644 .profiles.mk 2>/dev/null || true
fi
# 确保所有 .mk 文件可读
find . -name "*.mk" -type f -exec chmod 644 {} \; 2>/dev/null || true
# 确保脚本可执行
find . -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true

# 选择设备 Profile
case "$TARGET-$SUBTARGET" in
    "x86-64") 
        # 查看有哪些可用的 profile
        echo "查询可用的 x86/64 profiles..."
        AVAILABLE_PROFILES=$(make info 2>/dev/null | grep -E "x86|generic|64" || echo "")
        echo "$AVAILABLE_PROFILES"
        
        # 尝试找到正确的 profile 名称
        if echo "$AVAILABLE_PROFILES" | grep -q "Generic"; then
            DEVICE_PROFILE="Generic"
        elif echo "$AVAILABLE_PROFILES" | grep -qi "generic"; then
            # 提取完整的 profile 名称
            DEVICE_PROFILE=$(echo "$AVAILABLE_PROFILES" | grep -i "generic" | head -1 | awk '{print $1}')
        else
            # 使用第一个可用的 profile
            DEVICE_PROFILE=$(make info 2>/dev/null | grep -v "^$" | head -1 | awk '{print $1}')
        fi
        ;;
    "rockchip-armv8") 
        DEVICE_PROFILE="friendlyarm_nanopi-r4s"
        ;;
    "mediatek-filogic") 
        DEVICE_PROFILE="xiaomi_ax6000"
        ;;
    *) 
        DEVICE_PROFILE="generic"
        ;;
esac

echo "目标: $TARGET/$SUBTARGET | Profile: $DEVICE_PROFILE | 固件大小: ${ROM_SIZE}MB"

# 构建固件
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

# 输出固件
echo "构建完成，复制固件文件到输出目录..."
mkdir -p /home/build/custom/output

# 从构建目录复制文件（不修改权限，避免 Operation not permitted 错误）
if [ -d "$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET" ]; then
    cp -rv $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET/* /home/build/custom/output/
else
    echo "❌ 未找到构建输出目录: $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
    echo "搜索 bin 目录..."
    find "$BUILDER_DIR" -type d -name "bin" 2>/dev/null
    exit 1
fi

echo "输出的固件文件列表:"
ls -lh /home/build/custom/output/