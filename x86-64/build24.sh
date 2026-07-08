#!/bin/bash
source /home/build/custom/shell/custom-packages.sh

# 进入编译环境
cd /home/build/openwrt || cd /home/build/immortalwrt || cd /

echo "正在执行构建..."
echo "固件大小: ${PROFILE}MB"
echo "镜像类型: ${IMAGE_TYPES:-全部}"

# 根据 IMAGE_TYPES 构建
if [ -z "$IMAGE_TYPES" ] || [[ "$IMAGE_TYPES" == *"all"* ]]; then
    # 构建全部（默认行为）
    make image \
      PROFILE="generic" \
      PACKAGES="$CUSTOM_PACKAGES" \
      FILES="/home/build/custom/files" \
      ROOTFS_PARTSIZE=$PROFILE
else
    # 构建指定的镜像
    IMAGES_LIST=""
    
    # combined-efi-ext4
    if [[ "$IMAGE_TYPES" == *"combined-efi-ext4"* ]]; then
        IMAGES_LIST="$IMAGES_LIST ext4-combined-efi.img.gz ext4-combined-efi.qcow2 ext4-combined-efi.vdi ext4-combined-efi.vhdx ext4-combined-efi.vmdk"
    fi
    
    # combined-efi-squashfs
    if [[ "$IMAGE_TYPES" == *"combined-efi-squashfs"* ]]; then
        IMAGES_LIST="$IMAGES_LIST squashfs-combined-efi.img.gz squashfs-combined-efi.qcow2 squashfs-combined-efi.vdi squashfs-combined-efi.vhdx squashfs-combined-efi.vmdk"
    fi
    
    # combined-ext4
    if [[ "$IMAGE_TYPES" == *"combined-ext4"* ]]; then
        IMAGES_LIST="$IMAGES_LIST ext4-combined.img.gz ext4-combined.qcow2 ext4-combined.vdi ext4-combined.vhdx ext4-combined.vmdk"
    fi
    
    # combined-squashfs
    if [[ "$IMAGE_TYPES" == *"combined-squashfs"* ]]; then
        IMAGES_LIST="$IMAGES_LIST squashfs-combined.img.gz squashfs-combined.qcow2 squashfs-combined.vdi squashfs-combined.vhdx squashfs-combined.vmdk"
    fi
    
    # rootfs-ext4
    if [[ "$IMAGE_TYPES" == *"rootfs-ext4"* ]]; then
        IMAGES_LIST="$IMAGES_LIST ext4-rootfs.img.gz"
    fi
    
    # rootfs-squashfs
    if [[ "$IMAGE_TYPES" == *"rootfs-squashfs"* ]]; then
        IMAGES_LIST="$IMAGES_LIST squashfs-rootfs.img.gz"
    fi
    
    # rootfs-targz
    if [[ "$IMAGE_TYPES" == *"rootfs-targz"* ]]; then
        IMAGES_LIST="$IMAGES_LIST targz-rootfs.tar.gz"
    fi
    
    # iso-efi
    if [[ "$IMAGE_TYPES" == *"iso-efi"* ]]; then
        IMAGES_LIST="$IMAGES_LIST image-efi.iso"
    fi
    
    # iso
    if [[ "$IMAGE_TYPES" == *"iso"* ]]; then
        IMAGES_LIST="$IMAGES_LIST image.iso"
    fi
    
    # 去除首尾空格
    IMAGES_LIST=$(echo "$IMAGES_LIST" | xargs)
    
    echo "构建镜像列表: $IMAGES_LIST"
    
    if [ -n "$IMAGES_LIST" ]; then
        make image \
          PROFILE="generic" \
          PACKAGES="$CUSTOM_PACKAGES" \
          FILES="/home/build/custom/files" \
          ROOTFS_PARTSIZE=$PROFILE \
          IMAGES="$IMAGES_LIST"
    else
        echo "❌ 未指定有效的镜像类型"
        exit 1
    fi
fi

# 检查结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    mkdir -p /home/build/custom/output
    cp -r /home/build/openwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null || \
    cp -r /home/build/immortalwrt/bin/targets/x86/64/* /home/build/custom/output/ 2>/dev/null
    echo "构建产物："
    ls -la /home/build/custom/output/
else
    echo "❌ 构建失败"
    exit 1
fi