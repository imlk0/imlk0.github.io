---
title: "在Docker Compose中部署你的DN42节点"
date: 2022-02-23T22:49:33+08:00
categories:
  - Network
tags:
  - DN42
  - BGP
  - Docker
---

其实这篇文章攒了很久一直没有写，其中一个原因是DN42的入门教程太多了，再发也就重复了。但是又很想写点东西毕竟这个也折腾了一段时间，于是在某个夜深人静的夜晚，~~不想干活~~无所事事的我决定整理一下水一篇:)。

# 初见DN42

我大概是去年冬天的时候入坑了DN42，主要是看MiaoTony和Lan Tian的blog去注册。然后由于当时受到某位好友的「All in docker-compose.yaml」文化的感染，我萌生了把DN42的服务用docker-compose脚本去定义的想法。

# DN42 with docker-compose

基于docker-compose有这么一些好处：

1. 安全性。通常来说，dn42教程里会需要你在主机上执行包括关闭防火墙之类的操作。使用docker-compose方案可以避免这一问题，同时将主机上的其它私有服务与dn42网络做隔离。
2. 方便扩展dn42节点。只需要rsync到新的机器上，改改配置就能开一个新的Route Server。
3. 配置错误后随时remake。`docker down && docker up`又是全新的一天。
4. 可以在docker-compose.yaml里直接完成ip地址的静态分配，结合[IPAM](https://docs.docker.com/compose/compose-file/#ipam)，可以为不同的Route Server划分地址段。

也有这么一些缺点：
1. 网络变得复杂：我们的设想是把在docker中定义一个bridge网络，所有的bgp、dns、lookingglass等dn42服务全部挂到这个bridge网络上。
2. 有一些坑：当然我基本上都帮你填好了。


那么话不多说，我将代码放入到了这个仓库里 👉 [dn42-stuffs](https://github.com/KB5201314/dn42-stuffs)

由于每个人的口味不同，建议您clone下来之后按照自己的意愿去修改

> 对了我的ASN是`4242421742`，欢迎联系我peer（太懒了没写自动peer服务，要是有人捐赠一个Pull Request给咱就好了）


# 一些排错经验

## 使用ip6tables追踪数据包

### 设置追踪

可以直接参考[这篇文章](https://sleeplessbeastie.eu/2020/11/13/how-to-trace-packets-as-they-pass-through-the-firewall/)，在raw表上的`PREROUTING`或者`OUTPUT`表上设置`-j TRACE`。

比如下面是追踪进入到该主机的icmpv6包：

```sh
ip6tables -t raw -A PREROUTING -p icmpv6 -j TRACE
```

### 查看追踪日志

旧版内核通常使用`modprobe ipt_LOG`，例如[这里](https://www.opsist.com/blog/2015/08/11/how-do-i-see-what-iptables-is-doing.html)所介绍的。

但是由于博主的kernel比较新，现在使用`nf_log_*`系列模块：

```sh
modprobe nf_log_ipv6
sysctl net.netfilter.nf_log.10=nf_log_ipv6
```

需要注意的是`nf_log.`后面的数字实际上对应着协议编号，具体值是取决于代码中定义的，比如我们想观察的ipv6协议对应`AF_INET6`的值为`10`，而ipv4对应的`AF_INET`值为2。这下netfiliter框架会将trace打印到内核消息中。

查看日志[一般的方法](https://www.opensourcerers.org/2016/05/27/how-to-trace-iptables-in-rhel7-centos7/)都是先配置`rsyslog`输出日志，然后去看`kern.*`被输出到的地方，也有直接用`dmesg`查看的。但是测试发现并不管用，猜测是netns隔离的原因。

最后在[nftables官方文档](https://wiki.nftables.org/wiki-nftables/index.php/Ruleset_debug/tracing)这里找到另一种方法来查看：

首先必须确保当前的shell处在上面执行`ip6table`时同一个netns里面，否则看不到日志。

然后使用nftables查看trace记录：

```sh
nft monitor trace
```

就会显示出`-j TRACE`的记录。

## 排错过程一

进行一次从`fd42:d2aa:8a0e::3` 主机A到 ip为`fd42:d42:d42:54::1`的目标T的ping6。其中网关G的ip为`fd42:d2aa:8a0e::2`。

主机A和网关G均为docker container。

现象是：echo-request包到达网关G后并没有被转发出来。并且**任何来源的ipv6包网关G都不做转发**。

在网关G的netns中使用iptables设置追踪：

```sh
ip6tables -t raw -A PREROUTING -p icmpv6 --destination fd42:d42:d42:54::1 -j TRACE
```

追踪日志如下：

```
trace id e4a36c57 ip6 raw PREROUTING packet: iif "eth0" ether saddr 02:42:ac:16:60:03 ether daddr 02:42:ac:16:60:02 ip6 saddr fd42:d2aa:8a0e::3 ip6 daddr fd42:d42:d42:54::1 ip6 dscp cs0 ip6 ecn not-ect ip6 hoplimit 64 ip6 flowlabel 668322 ip6 length 64 icmpv6 type echo-request icmpv6 code no-route icmpv6 parameter-problem 27197440 @th,64,96 13911993890790384138924851200 
trace id e4a36c57 ip6 raw PREROUTING rule meta l4proto ipv6-icmp ip6 daddr fd42:d42:d42:54::1 counter packets 19226 bytes 1999504 meta nftrace set 1 (verdict continue)
trace id e4a36c57 ip6 raw PREROUTING verdict continue 
trace id e4a36c57 ip6 raw PREROUTING policy accept 
```

显示packet到`PREROUTING`之后就消失了，[查阅资料](https://unix.stackexchange.com/questions/690999/ipv6-forwarding-doesnt-work-in-a-network-namespace)发现，sysctl的`net.*`是能够感知netns（network-namespace aware）的，而**在创建container的netns时，`net.ipv6.conf.all.forwarding=1`设置并未从init_net继承**（该行为由[net.core.devconf_inherit_init_net](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/Documentation/admin-guide/sysctl/net.rst?h=v5.8#n332)控制），因此需要在网关G容器中额外设置开启ipv6的forwarding：

```sh
sysctl -w net.ipv6.conf.all.forwarding=1
```

设置完成后通过tcpdump发现，echo-request被发出并且目标T返回的echo-reply抵达网关G。

## 排错过程二

上面的问题解决后，echo-reply抵达了网关G，但是另一个问题是echo-reply并没有被转发给主机A。

测试发现**任何外面的DN42主机的包都无法进来，简单来说：只出不进。**

在网关G上设置raw表上PREROUTING的trace：

```sh
ip6tables -t raw -A PREROUTING -p icmpv6 --destination fd42:d2aa:8a0e::3 -j TRACE
```

结果显示echo-reply断在了raw表的PREROUTING链上：

```
trace id c9fb2605 ip6 raw PREROUTING packet: iif "wg-4242422688" ip6 saddr fd42:d42:d42:54::1 ip6 daddr fd42:d2aa:8a0e::3 ip6 dscp cs0 ip6 ecn not-ect ip6 hoplimit 62 ip6 flowlabel 808330 ip6 length 64 icmpv6 type echo-reply icmpv6 code no-route icmpv6 parameter-problem 11339418 @th,64,96 62617626364244974739948306432 
trace id c9fb2605 ip6 raw PREROUTING rule meta l4proto ipv6-icmp ip6 daddr fd42:d2aa:8a0e::3 counter packets 17107 bytes 1779128 meta nftrace set 1 (verdict continue)
trace id c9fb2605 ip6 raw PREROUTING rule ip6 daddr fd42:d2aa:8a0e::3 counter packets 15984 bytes 1656726 meta nftrace set 1 (verdict continue)
trace id c9fb2605 ip6 raw PREROUTING rule meta l4proto ipv6-icmp ip6 daddr fd42:d2aa:8a0e::3 counter packets 7 bytes 728 meta nftrace set 1 (verdict continue)
trace id c9fb2605 ip6 raw PREROUTING verdict continue 
trace id c9fb2605 ip6 raw PREROUTING policy accept 
```

但是netns中的防火墙规则并未拦截，并且trace也没有显示哪一条规则drop了这个packet。

排查后发现原因是主机A和网关G均为docker container，它们之间的网络经由docker主机上的bridge相连，因此还受到docker主机上防火墙的影响。

在docker主机上trace：

```sh
ip6tables -t raw -A PREROUTING -p icmpv6 --destination fd42:d2aa:8a0e::3 -j TRACE
```

```
trace id 698de359 ip6 raw PREROUTING packet: iif "br-94f3521ab04f" ether saddr 02:42:ac:16:60:02 ether daddr 02:42:ac:16:60:03 ip6 saddr fd42:d42:d42:54::1 ip6 daddr fd42:d2aa:8a0e::3 ip6 dscp cs0 ip6 ecn not-ect ip6 hoplimit 61 ip6 flowlabel 808330 ip6 length 64 icmpv6 type echo-reply icmpv6 code no-route icmpv6 parameter-problem 11339711 @th,64,96 4913746139972088583361134592 
trace id 698de359 ip6 raw PREROUTING rule meta l4proto ipv6-icmp ip6 daddr fd42:d2aa:8a0e::3 counter packets 2 bytes 176 meta nftrace set 1 (verdict continue)
trace id 698de359 ip6 raw PREROUTING verdict continue 
trace id 698de359 ip6 raw PREROUTING policy accept 
trace id 698de359 inet firewalld raw_PREROUTING packet: iif "br-94f3521ab04f" ether saddr 02:42:ac:16:60:02 ether daddr 02:42:ac:16:60:03 ip6 saddr fd42:d42:d42:54::1 ip6 daddr fd42:d2aa:8a0e::3 ip6 dscp cs0 ip6 ecn not-ect ip6 hoplimit 61 ip6 flowlabel 808330 ip6 nexthdr ipv6-icmp ip6 length 64 icmpv6 type echo-reply icmpv6 code no-route icmpv6 parameter-problem 11339711 @th,64,96 4913746139972088583361134592 
trace id 698de359 inet firewalld raw_PREROUTING rule meta nfproto ipv6 fib saddr . iif oif missing drop (verdict drop)
```

结果显示断在了**docker主机上firewalld防火墙的一条规则**上，使用nft查看这条规则：

```sh
sudo nft list chain inet firewalld raw_PREROUTING;
```

```
table inet firewalld {
        chain raw_PREROUTING {
                type filter hook prerouting priority raw + 10; policy accept;
                icmpv6 type { nd-router-advert, nd-neighbor-solicit } accept
                meta nfproto ipv6 fib saddr . iif oif missing drop
        }
}
```

（没想到host主机上的防火墙会作用在docker的bridge网络上）

关键在于那行`drop`语句，是对ipv6数据包的来源地址进行反向检查，检查当前这个包的来源地址是否和，回复该地址时的interface一致。

该行为是`/etc/firewalld/firewalld.conf`的[IPv6_rpfilter/etc/firewalld/firewalld.conf选项](https://firewalld.org/documentation/configuration/firewalld-conf.html)控制的，需要将其改为：

```
IPv6_rpfilter=no
```

对于nftables的更多使用方法以及概念学习，推荐看RedHat的[这份文档](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/getting-started-with-nftables_configuring-and-managing-networking)。

# 参考文档

- [Nftables and the Netfilter logging framework](https://home.regit.org/2014/02/nftables-and-netfilter-logging-framework/)
- [nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php)
- [TLDP - Linux IPv6 HOWTO (en) - Firewalling using nftables](https://tldp.org/HOWTO/Linux+IPv6-HOWTO/ch18s05.html)
