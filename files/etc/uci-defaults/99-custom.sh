#!/bin/sh

# 1. 批量配置 UCI 网络与 DHCP
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

# 2. 写入 sysctl 内核优化参数
SYSCTL_CONF="/etc/sysctl.conf"
sed -i '/vm.vfs_cache_pressure/d' $SYSCTL_CONF
sed -i '/vm.min_free_kbytes/d' $SYSCTL_CONF

cat << 'PARAM' >> $SYSCTL_CONF
vm.vfs_cache_pressure = 200
vm.min_free_kbytes = 8192
PARAM

# 3. 设为开机自启（固件已内置 zram-swap）
if [ -f "/etc/init.d/zram" ]; then
    /etc/init.d/zram enable
fi

exit 0