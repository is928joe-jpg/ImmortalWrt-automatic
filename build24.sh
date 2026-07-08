#!/bin/bash
set -e

echo "========================================="
echo "🍞 构建脚本开始"
echo "  TARGET_ARCH=$TARGET_ARCH"
echo "  TARGET=$TARGET"
echo "  SUBTARGET=$SUBTARGET"
echo "  容器内用户: $(id)"
echo "========================================="

echo "🍞 加载自定义包列表"
source /home/build/custom/shell/custom-packages.sh
echo "  CUSTOM_PACKAGES=$CUSTOM_PACKAGES"

echo "🍞 进入 ImageBuilder 目录"
BUILDER_DIR="/home/build/immortalwrt"
cd "$BUILDER_DIR"
echo "  工作目录: $(pwd)"

echo "🍞 查看 make info"
make info

echo "🍞 选择 Profile"
case "$TARGET_ARCH" in
    "x86-64")
        # x86-64 不需要指定 PROFILE
        PROFILE_PARAM=""
        ;;
    "rockchip-armv8")
        PROFILE_PARAM='PROFILE="friendlyarm_nanopi-r4s"'
        ;;
    "mediatek-filogic")
        PROFILE_PARAM='PROFILE="xiaomi_ax6000"'
        ;;
    *)
        PROFILE_PARAM=""
        ;;
esac

echo "🍞 构建固件"
if [ -n "$PROFILE_PARAM" ]; then
    echo "  使用 Profile: $PROFILE_PARAM"
    eval "make image $PROFILE_PARAM PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE"
else
    echo "  不使用 Profile（默认）"
    make image \
      PACKAGES="$CUSTOM_PACKAGES" \
      FILES="/home/build/custom/files" \
      ROOTFS_PARTSIZE=$ROM_SIZE
fi

echo "🍞 查找输出"
OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
echo "  查找: $OUTPUT_DIR"
if [ -d "$OUTPUT_DIR" ]; then
    echo "  ✅ 找到输出目录"
    ls -lh "$OUTPUT_DIR/"
else
    echo "  ❌ 未找到输出目录"
    find . -type d -name "bin"
    exit 1
fi

echo "🍞 复制固件到临时目录"
TEMP_OUT="/tmp/firmware"
mkdir -p "$TEMP_OUT"
cp -rv "$OUTPUT_DIR/"* "$TEMP_OUT/"
echo "  ✅ 已复制到 $TEMP_OUT"

echo "🍞 复制到宿主机 output 目录"
mkdir -p /home/build/custom/output
if command -v sudo &> /dev/null; then
    sudo cp -rv "$TEMP_OUT/"* /home/build/custom/output/
    sudo chmod -R 755 /home/build/custom/output
else
    cp -rv "$TEMP_OUT/"* /home/build/custom/output/ || {
        echo "  ⚠️ 直接复制失败，尝试使用 tar"
        tar cf - -C "$TEMP_OUT" . | tar xf - -C /home/build/custom/output/
    }
fi

echo "🍞 最终输出"
ls -lh /home/build/custom/output/
echo "🎉 构建完成"