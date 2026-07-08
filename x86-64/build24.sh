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
echo "尝试的路径:"
for dir in "/home/build/immortalwrt" "/builder" "/home/build"; do
    if [ -d "$dir" ]; then
        echo "  ✅ 目录存在: $dir"
        if [ -f "$dir/Makefile" ]; then
            echo "  ✅ 找到 Makefile: $dir/Makefile"
            BUILDER_DIR="$dir"
            break
        else
            echo "  ❌ $dir 中没有 Makefile"
            ls -la "$dir/" | head -5
        fi
    else
        echo "  ❌ 目录不存在: $dir"
    fi
done

if [ -z "$BUILDER_DIR" ]; then
    echo "🔍 搜索包含 Makefile 的目录..."
    find / -maxdepth 4 -name "Makefile" -exec grep -l "image.mk\|ImageBuilder" {} \; 2>/dev/null | while read f; do
        echo "  找到: $f"
    done
    exit 1
fi

echo "  🎯 使用 BUILD_DIR=$BUILDER_DIR"
cd "$BUILDER_DIR"
echo "  当前工作目录: $(pwd)"
echo "  Makefile 存在: $([ -f "Makefile" ] && echo "✅" || echo "❌")"
echo "  .profiles.mk 存在: $([ -f ".profiles.mk" ] && echo "✅" || echo "❌")"
echo "  目录结构顶层:"
ls -la | head -10

echo "========================================="
echo "🍞 面包屑 4: 修复文件权限"
echo "  修复前 .profiles.mk 权限:"
ls -la .profiles.mk 2>/dev/null || echo "  文件不存在"
echo "  修复前 target/ 目录权限:"
ls -la target/ 2>/dev/null | head -5
echo "  修复前 scripts/ 目录权限:"
ls -la scripts/ 2>/dev/null | head -5

# 修复权限
chmod 644 .profiles.mk 2>/dev/null && echo "  ✅ .profiles.mk 权限已修复" || echo "  ⚠️ .profiles.mk 权限修复失败"
chmod 644 .config 2>/dev/null && echo "  ✅ .config 权限已修复" || echo "  ⚠️ .config 不存在或修复失败"
find . -name "*.mk" -type f -exec chmod 644 {} \; 2>/dev/null && echo "  ✅ *.mk 文件权限已修复" || echo "  ⚠️ *.mk 文件权限修复失败"
find . -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null && echo "  ✅ *.sh 文件权限已修复" || echo "  ⚠️ *.sh 文件权限修复失败"

echo "  修复后 .profiles.mk 权限:"
ls -la .profiles.mk 2>/dev/null || echo "  文件不存在"

echo "========================================="
echo "🍞 面包屑 5: 查询可用设备 profiles"
echo "  make info 输出:"
make info
echo "  profiles 查询完毕"
echo "  检查 target/linux/$TARGET/ 目录:"
if [ -d "target/linux/$TARGET" ]; then
    echo "  ✅ target/linux/$TARGET/ 存在"
    ls -la "target/linux/$TARGET/"
    echo "  设备配置文件:"
    find "target/linux/$TARGET" -name "*.mk" -exec echo "  找到: {}" \;
else
    echo "  ❌ target/linux/$TARGET/ 不存在"
    echo "  target/linux/ 目录内容:"
    ls -la target/linux/ 2>/dev/null || echo "  目录不存在"
fi

echo "========================================="
echo "🍞 面包屑 6: 选择设备 Profile"
case "$TARGET-$SUBTARGET" in
    "x86-64") 
        DEVICE_PROFILE="generic"
        echo "  架构: x86-64 → Profile: $DEVICE_PROFILE"
        ;;
    "rockchip-armv8") 
        DEVICE_PROFILE="friendlyarm_nanopi-r4s"
        echo "  架构: rockchip-armv8 → Profile: $DEVICE_PROFILE"
        ;;
    "mediatek-filogic") 
        DEVICE_PROFILE="xiaomi_ax6000"
        echo "  架构: mediatek-filogic → Profile: $DEVICE_PROFILE"
        ;;
    *) 
        DEVICE_PROFILE="generic"
        echo "  架构: $TARGET-$SUBTARGET → 使用默认 Profile: $DEVICE_PROFILE"
        ;;
esac

echo "========================================="
echo "🍞 面包屑 7: 构建参数汇总"
echo "  TARGET=$TARGET"
echo "  SUBTARGET=$SUBTARGET"
echo "  PROFILE=$DEVICE_PROFILE"
echo "  PACKAGES=$CUSTOM_PACKAGES"
echo "  ROOTFS_PARTSIZE=$ROM_SIZE"
echo "  FILES=/home/build/custom/files"
echo "  检查 files 目录:"
if [ -d "/home/build/custom/files" ]; then
    echo "  ✅ /home/build/custom/files 存在"
    echo "  files 目录内容:"
    find /home/build/custom/files -type f 2>/dev/null | while read f; do
        echo "    📄 $f ($(wc -c < "$f") bytes)"
    done
else
    echo "  ⚠️ /home/build/custom/files 不存在"
fi

echo "========================================="
echo "🍞 面包屑 8: 开始执行 make image"
echo "命令: make image PROFILE=$DEVICE_PROFILE PACKAGES=... FILES=... ROOTFS_PARTSIZE=$ROM_SIZE"
make image \
  PROFILE="$DEVICE_PROFILE" \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

echo "========================================="
echo "🍞 面包屑 9: make 命令执行完成"
echo "make 退出码: $?"

echo "========================================="
echo "🍞 面包屑 10: 查找构建输出文件"
echo "搜索构建输出目录..."
echo "检查路径 1: $BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET/"
if [ -d "$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET" ]; then
    echo "  ✅ 找到标准输出路径"
    OUTPUT_DIR="$BUILDER_DIR/bin/targets/$TARGET/$SUBTARGET"
else
    echo "  ❌ 标准路径不存在"
    echo "  搜索所有 bin 目录:"
    find "$BUILDER_DIR" -type d -name "bin" -exec echo "  找到: {}" \; 2>/dev/null
    echo "  搜索固件文件:"
    find "$BUILDER_DIR" -type f \( -name "*.img.gz" -o -name "*.bin" -o -name "*.manifest" \) -exec echo "  找到: {}" \; 2>/dev/null
    exit 1
fi

echo "输出目录内容:"
ls -lh "$OUTPUT_DIR/"
echo "输出文件总数: $(ls -1 "$OUTPUT_DIR/" | wc -l)"

echo "========================================="
echo "🍞 面包屑 11: 复制文件到输出目录"
echo "目标: /home/build/custom/output/"
mkdir -p /home/build/custom/output
echo "创建输出目录: $([ -d "/home/build/custom/output" ] && echo '✅' || echo '❌')"
echo "输出目录权限: $(ls -ld /home/build/custom/output)"

echo "开始复制..."
cp -rv "$OUTPUT_DIR/"* /home/build/custom/output/
CP_EXIT=$?
echo "复制完成，退出码: $CP_EXIT"

echo "========================================="
echo "🍞 面包屑 12: 最终输出文件列表"
echo "输出目录: /home/build/custom/output/"
ls -lh /home/build/custom/output/
echo "文件总大小:"
du -sh /home/build/custom/output/
echo "========================================="
echo "🎉 构建脚本执行完毕"
echo "========================================="