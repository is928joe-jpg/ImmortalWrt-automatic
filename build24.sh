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
echo "  容器内 HOME: $HOME"
echo "  /home/build/custom 目录内容:"
ls -la /home/build/custom/
echo "========================================="

echo "🍞 面包屑 2: 加载自定义包列表"
CUSTOM_PACKAGES_FILE="/home/build/custom/shell/custom-packages.sh"
if [ -f "$CUSTOM_PACKAGES_FILE" ]; then
    echo "  ✅ 找到: $CUSTOM_PACKAGES_FILE"
    echo "  文件内容:"
    cat "$CUSTOM_PACKAGES_FILE"
    source "$CUSTOM_PACKAGES_FILE"
    echo "  加载结果: CUSTOM_PACKAGES=$CUSTOM_PACKAGES"
else
    echo "  ❌ 未找到: $CUSTOM_PACKAGES_FILE"
    echo "  shell 目录内容:"
    ls -la /home/build/custom/shell/ 2>/dev/null || echo "  shell 目录不存在"
    CUSTOM_PACKAGES=""
fi
echo "========================================="

echo "🍞 面包屑 3: 加载 imm.config 配置"
# 优先级: $TARGET_ARCH/imm.config > files/imm.config
if [ -f "/home/build/custom/$TARGET_ARCH/imm.config" ]; then
    CONFIG_FILE="/home/build/custom/$TARGET_ARCH/imm.config"
    echo "  📄 使用架构特定配置: $CONFIG_FILE"
elif [ -f "/home/build/custom/files/imm.config" ]; then
    CONFIG_FILE="/home/build/custom/files/imm.config"
    echo "  📄 使用统一配置: $CONFIG_FILE"
else
    CONFIG_FILE=""
    echo "  ⚠️ 未找到任何 imm.config"
    echo "  检查路径:"
    echo "    /home/build/custom/$TARGET_ARCH/imm.config: $([ -f /home/build/custom/$TARGET_ARCH/imm.config ] && echo '✅' || echo '❌')"
    echo "    /home/build/custom/files/imm.config: $([ -f /home/build/custom/files/imm.config ] && echo '✅' || echo '❌')"
fi

if [ -n "$CONFIG_FILE" ]; then
    echo "  配置内容:"
    echo "  ---BEGIN---"
    cat "$CONFIG_FILE"
    echo "  ---END---"
fi
echo "========================================="

echo "🍞 面包屑 4: 检查 FILES 目录"
FILES_DIR="/home/build/custom/files"
if [ -d "$FILES_DIR" ]; then
    echo "  ✅ FILES 目录存在: $FILES_DIR"
    echo "  目录结构:"
    find "$FILES_DIR" -type f -o -type d | sort | while read item; do
        if [ -d "$item" ]; then
            echo "    📁 $item"
        else
            echo "    📄 $item ($(wc -c < "$item") bytes)"
        fi
    done
else
    echo "  ⚠️ FILES 目录不存在: $FILES_DIR"
fi
echo "========================================="

echo "🍞 面包屑 5: 进入 ImageBuilder 目录"
BUILDER_DIR="/home/build/immortalwrt"
if [ -d "$BUILDER_DIR" ]; then
    echo "  ✅ ImageBuilder 目录存在"
else
    echo "  ❌ ImageBuilder 目录不存在: $BUILDER_DIR"
    echo "  搜索可能的目录:"
    find /home/build -maxdepth 2 -type d 2>/dev/null
    exit 1
fi

cd "$BUILDER_DIR"
echo "  工作目录: $(pwd)"
echo "  目录顶层文件:"
ls -la | head -15
echo "========================================="

echo "🍞 面包屑 6: 查看 make info"
echo "  执行 make info..."
make info
echo "  make info 执行完毕"
echo "========================================="

echo "🍞 面包屑 7: 应用 imm.config 到 .config"
if [ -n "$CONFIG_FILE" ]; then
    echo "  合并前 .config 行数: $(wc -l < .config 2>/dev/null || echo '0')"
    echo "  合并 $CONFIG_FILE..."
    cat "$CONFIG_FILE" >> .config
    echo "  合并后 .config 行数: $(wc -l < .config 2>/dev/null || echo '0')"
    echo "  新增的配置项:"
    cat "$CONFIG_FILE"
else
    echo "  无 imm.config，跳过合并"
fi
echo "========================================="

echo "🍞 面包屑 8: 确定 Profile 参数"
case "$TARGET_ARCH" in
    "x86-64")
        PROFILE_PARAM=""
        echo "  架构: x86-64 → 不指定 PROFILE（使用默认）"
        ;;
    "rockchip-armv8")
        PROFILE_PARAM='PROFILE="friendlyarm_nanopi-r4s"'
        echo "  架构: rockchip-armv8 → PROFILE=friendlyarm_nanopi-r4s"
        ;;
    "mediatek-filogic")
        PROFILE_PARAM='PROFILE="xiaomi_ax6000"'
        echo "  架构: mediatek-filogic → PROFILE=xiaomi_ax6000"
        ;;
    *)
        PROFILE_PARAM=""
        echo "  架构: $TARGET_ARCH → 不指定 PROFILE（使用默认）"
        ;;
esac
echo "========================================="

echo "🍞 面包屑 9: 构建参数汇总"
echo "  TARGET=$TARGET"
echo "  SUBTARGET=$SUBTARGET"
echo "  PROFILE_PARAM=$PROFILE_PARAM"
echo "  CUSTOM_PACKAGES=$CUSTOM_PACKAGES"
echo "  ROM_SIZE=$ROM_SIZE"
echo "  FILES_DIR=$FILES_DIR"
echo "========================================="

echo "🍞 面包屑 10: 开始构建固件"
if [ -n "$PROFILE_PARAM" ]; then
    echo "  执行命令:"
    echo "  make image $PROFILE_PARAM PACKAGES=\"...\" FILES=\"$FILES_DIR\" ROOTFS_PARTSIZE=$ROM_SIZE"
    eval "make image $PROFILE_PARAM PACKAGES=\"$CUSTOM_PACKAGES\" FILES=\"$FILES_DIR\" ROOTFS_PARTSIZE=$ROM_SIZE"
else
    echo "  执行命令:"
    echo "  make image PACKAGES=\"...\" FILES=\"$FILES_DIR\" ROOTFS_PARTSIZE=$ROM_SIZE"
    make image \
      PACKAGES="$CUSTOM_PACKAGES" \
      FILES="$FILES_DIR" \
      ROOTFS_PARTSIZE=$ROM_SIZE
fi
echo "  make image 执行完毕，退出码: $?"
echo "========================================="

echo "🍞 面包屑 11: 查找构建输出"
OUTPUT_DIR="$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
echo "  查找路径: $OUTPUT_DIR"
if [ -d "$OUTPUT_DIR" ]; then
    echo "  ✅ 找到输出目录"
    echo "  输出文件列表:"
    ls -lh "$OUTPUT_DIR/"
    echo "  文件数量: $(ls -1 "$OUTPUT_DIR/" | wc -l)"
    echo "  总大小:"
    du -sh "$OUTPUT_DIR/"
else
    echo "  ❌ 标准输出路径不存在"
    echo "  搜索 bin 目录:"
    find "$BUILDER_DIR" -type d -name "bin" -exec echo "    找到: {}" \; 2>/dev/null
    echo "  搜索固件文件:"
    find "$BUILDER_DIR" -type f \( -name "*.img.gz" -o -name "*.bin" -o -name "*.manifest" \) -exec echo "    找到: {}" \; 2>/dev/null
    exit 1
fi
echo "========================================="

echo "🍞 面包屑 12: 复制固件到临时目录"
TEMP_OUT="/tmp/firmware_output"
mkdir -p "$TEMP_OUT"
echo "  临时目录: $TEMP_OUT"
echo "  开始复制..."
cp -rv "$OUTPUT_DIR/"* "$TEMP_OUT/"
echo "  ✅ 复制完成"
echo "  临时目录内容:"
ls -lh "$TEMP_OUT/"
echo "========================================="

echo "🍞 面包屑 13: 复制到宿主机 output 目录"
HOST_OUTPUT="/home/build/custom/output"
mkdir -p "$HOST_OUTPUT"
echo "  目标目录: $HOST_OUTPUT"
echo "  目录权限: $(ls -ld "$HOST_OUTPUT" 2>/dev/null || echo '获取失败')"
echo "  目录可写: $([ -w "$HOST_OUTPUT" ] && echo '✅' || echo '❌')"

# 尝试多种复制方式
if command -v sudo &> /dev/null; then
    echo "  使用 sudo 复制..."
    sudo cp -rv "$TEMP_OUT/"* "$HOST_OUTPUT/" && echo "  ✅ sudo cp 成功" || echo "  ❌ sudo cp 失败"
    sudo chmod -R 755 "$HOST_OUTPUT" 2>/dev/null && echo "  ✅ sudo chmod 成功" || echo "  ⚠️ sudo chmod 失败"
else
    echo "  使用直接复制..."
    if cp -rv "$TEMP_OUT/"* "$HOST_OUTPUT/" 2>/dev/null; then
        echo "  ✅ 直接复制成功"
    else
        echo "  ⚠️ 直接复制失败，尝试 tar 方式..."
        if tar cf - -C "$TEMP_OUT" . | tar xf - -C "$HOST_OUTPUT/" 2>/dev/null; then
            echo "  ✅ tar 方式成功"
        else
            echo "  ❌ 所有复制方式都失败"
            echo "  尝试查看详细错误:"
            cp -rv "$TEMP_OUT/"* "$HOST_OUTPUT/"
        fi
    fi
fi
echo "========================================="

echo "🍞 面包屑 14: 最终输出验证"
echo "  宿主 output 目录内容:"
ls -lh "$HOST_OUTPUT/" 2>/dev/null || echo "  ❌ 无法列出 output 目录"
echo "  文件数量: $(ls -1 "$HOST_OUTPUT/" 2>/dev/null | wc -l)"
echo "  总大小: $(du -sh "$HOST_OUTPUT/" 2>/dev/null || echo '0')"
echo "========================================="
echo "🎉 构建脚本执行完毕"
echo "========================================="