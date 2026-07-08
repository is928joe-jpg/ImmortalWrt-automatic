#!/bin/sh
# 设置 LAN
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.proto='static'
uci set network.lan.ip6assign='64'
uci set network.lan.delegate='1'

# 设置 DHCP
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='50'
uci set dhcp.lan.ra='server'
uci set dhcp.lan.dhcpv6='server'
uci set dhcp.lan.ra_management='1'

# 设置 WAN IPv6
uci set network.wan6.proto='dhcpv6'
uci set network.wan6.reqaddress='try'
uci set network.wan6.reqprefix='auto'

uci commit network
uci commit dhcp
exit 0