#!/bin/bash
# generate-options.sh - 本地运行，生成完整 options 的 yml

set -e

VERSION="${1:-24.10.6}"
echo "🍞 获取版本 $VERSION 的架构..."

# 获取架构列表
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:immortalwrt/imagebuilder:pull" | jq -r '.token')
ARCHS=$(curl -sH "Authorization: Bearer $TOKEN" \
  "https://registry-1.docker.io/v2/immortalwrt/imagebuilder/tags/list?n=2000" | \
  jq -r '.tags[]' | grep "openwrt-${VERSION}$" | sed "s/-openwrt-${VERSION}//" | sort -u)

echo "=== 找到 $(echo "$ARCHS" | wc -l) 个架构 ==="

# 生成架构 options
ARCH_OPTIONS=""
for a in $ARCHS; do
    ARCH_OPTIONS+="          - $a"$'\n'
done

# 获取每个架构的设备
echo "🍞 获取设备列表..."
DEVICE_ENTRIES=""

for ARCH in $ARCHS; do
    echo "  处理: $ARCH"
    IMAGE="${ARCH}-openwrt-${VERSION}"
    
    DEVICES=$(docker run --rm immortalwrt/imagebuilder:$IMAGE \
        make info 2>/dev/null | grep -oP '^\s*\K[^\s:]+(?=:)' | \
        grep -v "Current\|Default\|Available\|Target\|Architecture\|Revision\|Packages" | sort -u)
    
    if [ -n "$DEVICES" ]; then
        for d in $DEVICES; do
            DEVICE_ENTRIES+="  $ARCH|$d"$'\n'
        done
        echo "    设备数: $(echo "$DEVICES" | wc -l)"
    else
        # x86-64 等没有 profile 的架构
        DEVICE_ENTRIES+="  $ARCH|generic"$'\n'
        echo "    默认: generic"
    fi
done

# 生成 step2-arch.yml
cat > .github/workflows/step2-arch.yml << 'YAML_HEAD'
name: "Step 2: 选择架构"

on:
  workflow_dispatch:
    inputs:
      version:
        description: "ImmortalWrt 版本"
        required: true
        type: string
        default: ''
      target_arch:
        description: "选择目标架构"
        required: true
        type: choice
        options:
YAML_HEAD

echo "$ARCH_OPTIONS" >> .github/workflows/step2-arch.yml

cat >> .github/workflows/step2-arch.yml << 'YAML_MID'

permissions:
  contents: write
  actions: write

jobs:
  get-devices:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
        with:
          token: ${{ secrets.PAT }}

      - name: 获取设备列表
        run: |
          ARCH="${{ github.event.inputs.target_arch }}"
          VERSION="${{ github.event.inputs.version }}"
          IMAGE="${ARCH}-openwrt-${VERSION}"
          
          echo "🍞 获取设备..."
          docker run --rm immortalwrt/imagebuilder:$IMAGE \
            make info 2>/dev/null | grep -oP '^\s*\K[^\s:]+(?=:)' | \
            grep -v "Current\|Default\|Available\|Target\|Architecture\|Revision\|Packages" | sort -u | tee /tmp/devices.txt

      - name: 更新 step3-build.yml
        run: |
          DEVICES=$(cat /tmp/devices.txt | tr '\n' ' ')
          [ -z "$DEVICES" ] && DEVICES="generic"
          
          python3 << 'EOF'
import re

with open('.github/workflows/step3-build.yml', 'r') as f:
    content = f.read()

options = ""
for d in """$DEVICES""".split():
    options += f"          - {d}\n"

content = re.sub(
    r'(device:.*?options:)\s*\n(.*?)(\n      [a-z])',
    '\\1\n' + options + '\\3',
    content,
    flags=re.DOTALL
)

with open('.github/workflows/step3-build.yml', 'w') as f:
    f.write(content)
EOF

      - name: 提交
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: "Auto: devices for ${{ github.event.inputs.target_arch }}"
          file_pattern: '.github/workflows/step3-build.yml'
YAML_MID

# 生成 step3-build.yml（带 TARGET/SUBTARGET 映射）
cat > .github/workflows/step3-build.yml << 'YAML_HEAD3'
name: "Step 3: 选择设备并构建"

on:
  workflow_dispatch:
    inputs:
      version:
        description: "ImmortalWrt 版本"
        required: true
        type: string
      target_arch:
        description: "目标架构"
        required: true
        type: string
      device:
        description: "选择设备"
        required: true
        type: choice
        options: []  # 由 step2 自动填充
      rom_size:
        description: "固件大小(MB)"
        required: true
        type: string
        default: '512'

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: 准备输出目录
        run: |
          mkdir -p output
          chmod 777 output

      - name: Build firmware
        run: |
          ARCH="${{ github.event.inputs.target_arch }}"
          DEVICE="${{ github.event.inputs.device }}"
          VERSION="${{ github.event.inputs.version }}"
          IMAGE="${ARCH}-openwrt-${VERSION}"

          # 解析 TARGET/SUBTARGET
          case "$ARCH" in
            x86-64)            TARGET="x86";    SUBTARGET="64" ;;
            x86-generic)       TARGET="x86";    SUBTARGET="generic" ;;
            x86-legacy)        TARGET="x86";    SUBTARGET="legacy" ;;
            x86-geode)         TARGET="x86";    SUBTARGET="geode" ;;
            *) 
              TARGET="${ARCH%%-*}"
              SUBTARGET="${ARCH#*-}"
              ;;
          esac

          if [ "$DEVICE" = "generic" ]; then
            PROFILE=""
          else
            PROFILE="PROFILE=\"$DEVICE\""
          fi

          docker run --rm -i \
            -v "${{ github.workspace }}:/home/build/custom" \
            -e TARGET="$TARGET" \
            -e SUBTARGET="$SUBTARGET" \
            -e PROFILE="$PROFILE" \
            -e ROM_SIZE="${{ github.event.inputs.rom_size }}" \
            immortalwrt/imagebuilder:$IMAGE \
            /bin/bash /home/build/custom/build24.sh

      - name: 修复输出权限
        if: always()
        run: |
          if [ -d "output" ]; then
            sudo chown -R $(id -u):$(id -g) output 2>/dev/null || true
            chmod -R 755 output 2>/dev/null || true
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ github.event.inputs.target_arch }}-${{ github.event.inputs.device }}-${{ github.event.inputs.version }}
          path: output/*

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.event.inputs.version }}-${{ github.run_id }}
          name: ImmortalWrt ${{ github.event.inputs.version }} - ${{ github.event.inputs.target_arch }}/${{ github.event.inputs.device }}
          body: |
            - 版本: ${{ github.event.inputs.version }}
            - 架构: ${{ github.event.inputs.target_arch }}
            - 设备: ${{ github.event.inputs.device }}
            - 固件大小: ${{ github.event.inputs.rom_size }} MB
          files: output/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
YAML_HEAD3

echo "✅ 生成完成"
echo "   step2-arch.yml: $(echo "$ARCHS" | wc -l) 个架构"
echo "   step3-build.yml: 待 step2 运行时填充设备列表"