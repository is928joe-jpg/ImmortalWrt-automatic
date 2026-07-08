#!/bin/bash
set -e

echo "========================================="
echo "🍞 面包屑 1: 脚本开始执行"
echo "当前环境变量:"
echo "  TARGET=$TARGET"
echo "  SUBTARGET=$SUBTARGET"
echo "  ROM_SIZE=$ROM_SIZE"
echo "  VERSION=$VERSION"
echo "  TARGET_ARCH=$TARGET_ARCH"
echo "  容器内用户: $(id)"
echo "  容器内 HOME: $HOME"
echo "  自定义目录内容:"
ls -la /home/build/custom/
echo "========================================="

echo "🍞 面包屑 2: 加载自定义包列表"
if [ -f "/home/build/custom/shell/custom-packages.sh" ]; then
    echo "  ✅ 找到 custom-packages.sh"
    cat /home/build/custom/shell/custom-packages.sh
    source /home/build/custom/shell/custom-packages.sh
    echo "  加载的 CUSTOM_PACKAGES=$CUSTOM_PACKAGES"
else
    echo "  ❌ 未找到 /home/build/custom/shell/custom-packages.sh"
    echo "  /home/build/custom/shell/ 目录内容:"
    ls -la /home/build/custom/shell/ 2>/dev/null || echo "  目录不存在"
    CUSTOM_PACKAGES=""
fi

echo "========================================="
echo "🍞 面包屑 3: 查找 ImageBuilder 目录"
BUILDER_DIR="/home/build/immortalwrt"
if [ -d "$BUILDER_DIR" ] && [ -f "$BUILDER_DIR/Makefile" ]; then
    echo "  ✅ 找到 ImageBuilder: $BUILDER_DIR"
else
    echo "  ❌ 标准路径不存在"
    for dir in "/builder" "/home/build"; do
        if [ -d "$dir" ] && [ -f "$dir/Makefile" ]; then
            echo "  ✅ 找到 ImageBuilder: $dir"
            BUILDER_DIR="$dir"
            break
        fi
    done
fi

cd "$BUILDER_DIR" || exit 1
echo "  当前工作目录: $(pwd)"
echo "  目录内容:"
ls -la | head -10

echo "========================================="
echo "🍞 面包屑 4: 修复文件权限"
chmod 644 .profiles.mk 2>/dev/null && echo "  ✅ .profiles.mk 权限已修复" || echo "  ⚠️ .profiles.mk 不存在"
chmod 644 .config 2>/dev/null && echo "  ✅ .config 权限已修复" || echo "  ⚠️ .config 不存在"
find . -name "*.mk" -type f -exec chmod 644 {} \; 2>/dev/null && echo "  ✅ *.mk 文件权限已修复" || true
find . -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null && echo "  ✅ *.sh 文件权限已修复" || true

echo "========================================="
echo "🍞 面包屑 5: 查询可用设备 profiles"
make info

echo "========================================="
echo "🍞 面包屑 6: 选择设备 Profile"
case "$TARGET-$SUBTARGET" in
    "x86-64") 
        DEVICE_PROFILE="generic"
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
echo "  Profile: $DEVICE_PROFILE"

echo "========================================="
echo "🍞 面包屑 7: 构建参数"
echo "  TARGET=$TARGET"
echo "  SUBTARGET=$SUBTARGET"
echo "  PROFILE=$DEVICE_PROFILE"
echo "  PACKAGES=$CUSTOM_PACKAGES"
echo "  ROOTFS_PARTSIZE=$ROM_SIZE"
echo "  FILES=/home/build/custom/files"
echo "  Files 目录: $([ -d /home/build/custom/files ] && echo '✅ 存在' || echo '⚠️ 不存在')"

echo "========================================="
echo "🍞 面包屑 8: 开始构建"
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

echo "========================================="
echo "🍞 面包屑 9: 构建完成，查找输出"
OUTPUT_DIR="$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
if [ -d "$OUTPUT_DIR" ]; then
    echo "  ✅ 找到输出: $OUTPUT_DIR"
    ls -lh "$OUTPUT_DIR/"
else
    echo "  ❌ 未找到: $OUTPUT_DIR"
    find "$BUILDER_DIR" -type d -name "bin" 2>/dev/null
    exit 1
fi

echo "========================================="
echo "🍞 面包屑 10: 复制到输出目录"
mkdir -p /home/build/custom/output
echo "  输出目录权限: $(ls -ld /home/build/custom/output)"
echo "  输出目录可写: $([ -w /home/build/custom/output ] && echo '✅' || echo '❌')"

cp -rv "$OUTPUT_DIR/"* /home/build/custom/output/
echo "  ✅ 复制完成"

echo "========================================="
echo "🍞 面包屑 11: 最终输出"
ls -lh /home/build/custom/output/
du -sh /home/build/custom/output/
echo "========================================="
echo "🎉 构建成功"