---
title: "Wiregurad How To"
date: 2021-12-17T11:52:36+08:00
draft: true
---


imlk-server:
zwRu4flBUgoWp+27kBDfJYV8CmQ+ZGRCzGYEzoP9v28=
192.168.233.1/24
imlk-pc:
PfdP0o0SiP9cQbDDjh6nLlbuKaDV+3I4z67grLNcBnY=
192.168.233.2/24
imlk-raspi:
192.168.233.3/24
imlk-android:
RE4b3d6nBsZx8cXGIaFygVgyL2MJUWo+fSHGBbY/pxI=
192.168.233.4/24
imlk-server-kunpeng:
+sCyrBZaL8aA4gFuRONaB6VQ91df5Rblsf0RI74043w=
192.168.233.5/24


ip link add dev wg0 type wireguard
ip link set dev wg0 mtu 1420
ip addr add 192.168.233.2/24 dev wg0
wg set wg0 listen-port 52840
wg set wg0 private-key <(wg genkey)

ip link set wg0 up


wg set wg0 peer zwRu4flBUgoWp+27kBDfJYV8CmQ+ZGRCzGYEzoP9v28= allowed-ips 192.168.233.0/24 endpoint imlk.top:52840

wg set wg0 peer PfdP0o0SiP9cQbDDjh6nLlbuKaDV+3I4z67grLNcBnY= allowed-ips 192.168.233.2/32 endpoint imlk-pc.ddns6.imlk.top:52840

wg set wg0 peer RE4b3d6nBsZx8cXGIaFygVgyL2MJUWo+fSHGBbY/pxI= allowed-ips 192.168.233.4/32

wg set wg0 peer +sCyrBZaL8aA4gFuRONaB6VQ91df5Rblsf0RI74043w= allowed-ips 192.168.233.5/32 endpoint kunpeng.imlk.top:52840


# 允许从wg0收到的包被转发到wg0
iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT -t filter
# 否则对于udp和tcp连接，可能遇到`No route to host`
# 如果你使用firewalld，请停止使用它，因为它的默认策略会阻止forward，且难以调整这种策略（这里花了我很多时间），建议换用nftables，或者如果你找到了办法可以告诉我（注意在firewall-cmd中配置masquerade可能会导致udp/tcp连接成功，但其本质是让服务器开启nat，且不说同一个网段里搞nat属实脑瘫，用起来的时也会有各种问题，毕竟不是正确的ip地址）：
systemctl stop firewalld.service


使用：
sysctl -w net.ipv4.conf.wg0.forwarding=1
而不是使用：
sysctl -w net.ipv4.ip_forward=1
可以减少安全风险，但是会导致无法使用wireguard进行路由转发。
然后向/etc/sysctl.conf追加net.ipv4.conf.wg0.forwarding=1



allowed IPs是什么意思：
In other words, when sending packets, the list of allowed IPs behaves as a sort of routing table, and when receiving packets, the list of allowed IPs behaves as a sort of access control list.

调试wireguard:
# modprobe wireguard 
# echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control
# dmesg -wH

缺陷：
如果client侧配置了server侧的enterpoint,而server侧没有client侧的enterpoint，由于使用UDP通信，当client处于NAT环境中时，NAT的端口映射在握手一段时间后失效。
直接的表现是，client侧随时都可以ping server侧，但是server侧不能ping client侧。直到client侧再次发起握手（如ping 一下 server侧），server侧才能ping client。
解决方法：
可以使用`persistent-keepalive 25`来保持连接。

