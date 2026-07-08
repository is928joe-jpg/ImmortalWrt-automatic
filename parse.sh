#!/bin/bash

# 假设当前目录就是下载好的 immortalwrt 源码根目录
echo "🍞 可用 profiles:"

# 遍历所有目标架构的 image 定义
find target/linux/*/image/ -name "*.mk" | while read -r mkfile; do
    awk '
    # 提取 Profile 名称
    /^define Device\// { 
        sub("define Device/", "", $1); 
        profile=$1; 
        print "\n" profile ":" 
    }
    # 提取标题
    /DEVICE_TITLE :=/ { 
        sub(".*:= ", "", $0); 
        print "    " $0 
    }
    # 提取包列表
    /DEVICE_PACKAGES :=/ { 
        sub(".*:= ", "    Packages: ", $0); 
        print $0 
    }
    # 提取支持设备标识
    /SUPPORTED_DEVICES :=/ { 
        sub(".*:= ", "    SupportedDevices: ", $0); 
        print $0 
    }
    ' "$mkfile"
done