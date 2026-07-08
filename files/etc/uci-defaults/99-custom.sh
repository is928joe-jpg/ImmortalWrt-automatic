#!/bin/sh

# 1. 批量配置 UCI (节省调用开销)
uci batch << EOF
set network.lan.ipaddr='192.168.1.1'
set network.lan.netmask='255.255.255.0'
set network.lan.proto='static'
set network.lan.ip6assign='64'
set network.lan.delegate='1'
set dhcp.lan.start='100'
set dhcp.lan.limit='50'
set dhcp.lan.ra='server'
set dhcp.lan.dhcpv6='server'
set dhcp.lan.ra_management='1'
set network.wan6.proto='dhcpv6'
set network.wan6.reqaddress='try'
set network.wan6.reqprefix='auto'
commit network
commit dhcp
EOF

# 2. 优化 sysctl 设置
sed -i '/vm.vfs_cache_pressure\|vm.min_free_kbytes/d' /etc/sysctl.conf
printf "vm.vfs_cache_pressure = 200\nvm.min_free_kbytes = 8192\n" >> /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

# 3. ZRAM 处理 (合并逻辑)
if [ -f "/etc/init.d/zram" ]; then
    /etc/init.d/zram enable && /etc/init.d/zram restart
    echo "ZRAM 已启动，状态如下："
    /etc/init.d/zram status | grep -E "Device size|Original data size|Memory used"
else
    echo "警告：未找到 ZRAM 服务。"
fi