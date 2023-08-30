---
title: "Private Network With Proxy ARP"
date: 2023-03-19T22:28:33+08:00
categories:
  - Network
tags:
  - Tailscale
  - Proxmox
  - ARP
draft: true
---

又到了办网时间，由于


发现之前的网络存在一个问题


tailscale

可以参考https://icloudnative.io/posts/how-to-set-up-or-migrate-headscale/


## proxy_arp介绍

Proxmox wiki的[Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)页中的`Routed Configuration`章节，其中有一条`echo 1 > /proc/sys/net/ipv4/conf/eno0/proxy_arp`，遂调查了`proxy_arp`这个配置


https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html
https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.bridging.proxy-arp.html
https://imliuda.com/post/1015

## 原先的配置

TODO: 可以做一个类似于[这个](https://pve.proxmox.com/pve-docs/images/default-network-setup-routed.svg)图里的组网描述方法

内网是`192.168.233.0/24`，其中前面16个主机号分给了wg组网的各个peer，包括这台proxmox主机，而里面定义了一个bridge网段为192.168.233.16/28，其中的`192.168.233.17`分给了proxmox。等于说proxmox持有了两个主ip。之所以这么搞，是因为当时在vm里配置`192.168.233.0/24`为link scope的路由后，ping不通前16个主机号，所以改成了主动在每个lxc container里用两条路由，
```sh
ip r add 192.168.233.16/28 dev eth1
ip r add 192.168.233.0/24 dev eth1 via 192.168.233.17
```
再由proxmox forward到前16个主机号中的目标主机勉强度日
以上路由条目，只有第一条可以在pve的面板中配置，第二条就需要手动在lxc container里配置了。



用上proxy_arp的配置：
host上改/etc/network/interfaces，加上最后一条
```
auto vmbr1
iface vmbr1 inet static
        address 192.168.233.17/28
        bridge-ports none
        bridge-stp off
        bridge-fd 0
        post-up echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up echo 1 > /proc/sys/net/ipv4/conf/$IFACE/proxy_arp
```
然后在proxmox面板里给每个lxc container/vm的网段从`192.168.233.16/28`配成`192.168.233.0/24`


## 总结

学到了`proxy_arp`这个配网技巧，以后配网的时候可以更加方便了。


