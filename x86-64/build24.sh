#!/bin/bash
set -e

echo "========================================="
echo "🍞 面包屑 1: 脚本开始执行"
echo "  容器内用户: $(id)"
echo "  当前目录: $(pwd)"
echo "  TARGET=$TARGET SUBTARGET=$SUBTARGET"
echo "========================================="

echo "🍞 面包屑 2: 加载自定义包列表"
source /home/build/custom/shell/custom-packages.sh
echo "  CUSTOM_PACKAGES=$CUSTOM_PACKAGES"

echo "========================================="
echo "🍞 面包屑 3: 进入 ImageBuilder 目录"
BUILDER_DIR="/home/build/immortalwrt"
cd "$BUILDER_DIR"
echo "  工作目录: $(pwd)"
echo "  检查 .profiles.mk: $(ls -la .profiles.mk 2>/dev/null || echo '不存在')"
echo "  检查 .config: $(ls -la .config 2>/dev/null || echo '不存在')"

echo "========================================="
echo "🍞 面包屑 4: 查看 make info"
make info
echo "  Available Profiles 上面是空的，说明不需要指定 PROFILE"

echo "========================================="
echo "🍞 面包屑 5: 构建固件（不指定 PROFILE）"
echo "  构建命令: make image PACKAGES=... FILES=... ROOTFS_PARTSIZE=$ROM_SIZE"

# 不指定 PROFILE，直接构建
make image \
  PACKAGES="$CUSTOM_PACKAGES" \
  FILES="/home/build/custom/files" \
  ROOTFS_PARTSIZE=$ROM_SIZE

echo "========================================="
echo "🍞 面包屑 6: 查找构建输出"
OUTPUT_DIR="bin/targets/$TARGET/$SUBTARGET"
echo "  查找: $OUTPUT_DIR"
if [ -d "$OUTPUT_DIR" ]; then
    echo "  ✅ 找到输出目录"
    ls -lh "$OUTPUT_DIR/"
else
    echo "  ❌ 未找到，搜索 bin 目录:"
    find . -type d -name "bin" 2>/dev/null
    exit 1
fi

echo "========================================="
echo "🍞 面包屑 7: 复制到 /tmp 临时目录"
TEMP_OUT="/tmp/firmware"
mkdir -p "$TEMP_OUT"
cp -rv "$OUTPUT_DIR/"* "$TEMP_OUT/"
echo "  ✅ 已复制到 $TEMP_OUT"
ls -lh "$TEMP_OUT/"

echo "========================================="
echo "🍞 面包屑 8: 复制到宿主机 output 目录"
mkdir -p /home/build/custom/output
# 使用 sudo 强制复制（如果有 sudo 权限）
if command -v sudo &> /dev/null; then
    sudo cp -rv "$TEMP_OUT/"* /home/build/custom/output/
    sudo chmod -R 755 /home/build/custom/output
else
    cp -rv "$TEMP_OUT/"* /home/build/custom/output/ || {
        echo "  ⚠️ 直接复制失败，尝试使用 tar"
        tar cf - -C "$TEMP_OUT" . | tar xf - -C /home/build/custom/output/
    }
fi

echo "========================================="
echo "🍞 面包屑 9: 最终输出"
ls -lh /home/build/custom/output/
echo "🎉 构建完成"