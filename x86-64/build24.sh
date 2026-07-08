#!/bin/bash
set -e

echo "========================================="
echo "🍞 面包屑 1: 脚本开始执行"
echo "  环境变量:"
echo "    TARGET_ARCH=$TARGET_ARCH"
echo "    TARGET=$TARGET"
echo "    SUBTARGET=$SUBTARGET"
echo "    ROM_SIZE=$ROM_SIZE"
echo "    VERSION=$VERSION"
echo "  容器内用户: $(id)"
echo "========================================="

echo "🍞 面包屑 2: 加载自定义包列表"
source /home/build/custom/shell/custom-packages.sh
echo "  CUSTOM_PACKAGES=$CUSTOM_PACKAGES"

echo "========================================="
echo "🍞 面包屑 3: 加载 imm.config"
if [ -f "/home/build/custom/$TARGET_ARCH/imm.config" ]; then
    CONFIG_FILE="/home/build/custom/$TARGET_ARCH/imm.config"
    echo "  📄 使用架构特定配置: $CONFIG_FILE"
elif [ -f "/home/build/custom/files/imm.config" ]; then
    CONFIG_FILE="/home/build/custom/files/imm.config"
    echo "  📄 使用统一配置: $CONFIG_FILE"
else
    CONFIG_FILE=""
    echo "  ⚠️ 未找到 imm.config"
fi

echo "========================================="
echo "🍞 面包屑 4: 进入 ImageBuilder 目录"
BUILDER_DIR="/home/build/immortalwrt"
cd "$BUILDER_DIR"
echo "  工作目录: $(pwd)"

echo "🍞 面包屑 5: 查看 make info"
make info

echo "========================================="
echo "🍞 面包屑 6: 应用 imm.config"
if [ -n "$CONFIG_FILE" ]; then
    echo "  合并 $CONFIG_FILE 到 .config"
    cat "$CONFIG_FILE" >> .config
    echo "  ✅ 配置已合并"
else
    echo "  跳过配置合并"
fi

echo "========================================="
echo "🍞 面包屑 7: 确定 Profile"
case "$TARGET_ARCH" in
    "x86-64")
        PROFILE_PARAM=""
        echo "  x86-64 → 不指定 PROFILE"
        ;;
    "rockchip-armv8")
        PROFILE_PARAM='PROFILE="friendlyarm_nanopi-r4s"'
        echo "  rockchip-armv8 → $PROFILE_PARAM"
        ;;
    "mediatek-filogic")
        PROFILE_PARAM='PROFILE="xiaomi_ax6000"'
        echo "  mediatek-filogic → $PROFILE_PARAM"
        ;;
    *)
        PROFILE_PARAM=""
        echo "  $TARGET_ARCH → 不指定 PROFILE"
        ;;
esac

echo "========================================="
echo "🍞 面包屑 8: 构建固件"
if [ -n "$PROFILE_PARAM" ]; then
    echo "  命令: make image $PROFILE_PARAM PACKAGES=... FILES=... ROOTFS_PARTSIZE=$ROM_SIZE"
    eval "make image $PROFILE_PARAM PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"/home/build/custom/files\" ROOTFS_PARTSIZE=$ROM_SIZE" 2>&1 | tee /tmp/make_output.log
    MAKE_EXIT=${PIPESTATUS[0]}
else
    echo "  命令: make image PACKAGES=... FILES=... ROOTFS_PARTSIZE=$ROM_SIZE"
    make image \
      PACKAGES="$CUSTOM_PACKAGES" \
      FILES="/home/build/custom/files" \
      ROOTFS_PARTSIZE=$ROM_SIZE 2>&1 | tee /tmp/make_output.log
    MAKE_EXIT=${PIPESTATUS[0]}
fi

if [ $MAKE_EXIT -ne 0 ]; then
    echo "========================================="
    echo "❌ 构建失败！退出码: $MAKE_EXIT"
    echo "========================================="
    echo "  最后 50 行输出:"
    tail -50 /tmp/make_output.log
    echo "========================================="
    echo "  搜索错误关键词:"
    grep -i "error\|failed\|cannot\|not found\|package" /tmp/make_output.log | tail -20
    echo "========================================="
    exit 1
fi
echo "  ✅ 构建成功"

echo "========================================="
echo "🍞 面包屑 9: 查找构建输出"
OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
echo "  查找: $OUTPUT_DIR"
if [ -d "$OUTPUT_DIR" ]; then
    echo "  ✅ 找到输出目录"
    ls -lh "$OUTPUT_DIR/"
else
    echo "  ❌ 未找到输出目录"
    find . -type d -name "bin" 2>/dev/null
    exit 1
fi

echo "========================================="
echo "🍞 面包屑 10: 复制到临时目录"
TEMP_OUT="/tmp/firmware"
mkdir -p "$TEMP_OUT"
cp -rv "$OUTPUT_DIR/"* "$TEMP_OUT/"

echo "========================================="
echo "🍞 面包屑 11: 复制到宿主机 output"
mkdir -p /home/build/custom/output
if command -v sudo &> /dev/null; then
    sudo cp -rv "$TEMP_OUT/"* /home/build/custom/output/
    sudo chmod -R 755 /home/build/custom/output
else
    cp -rv "$TEMP_OUT/"* /home/build/custom/output/ || {
        tar cf - -C "$TEMP_OUT" . | tar xf - -C /home/build/custom/output/
    }
fi

echo "========================================="
echo "🍞 面包屑 12: 最终输出"
ls -lh /home/build/custom/output/
echo "🎉 构建完成"