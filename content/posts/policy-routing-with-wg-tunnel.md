---
title: "在WireGuard场景中使用策略路由定义复杂路由规则"
date: 2022-11-29T15:55:46+08:00
categories:
  - Network
tags:
  - wireguard
  - ip-rule
draft: false
---

今日在配置网络时，遇到一个需求：

主机上有一个无线网卡`wlp44s0`连接到路由器，作为默认路由，还有docker和tailscale创建的一些杂七杂八的接口。现在的想法是，要新增一个wireguard隧道`wg0`连到内网的另一台机器上，让所有的通向外网的TCP流量经过`wg0`转发，其它不受影响。

WG的部分已经配好，且使用`Table = off`属性关闭了wireguard自动生成的路由规则。接下来需要解决我们自定义路由规则的需求。

# iptables fwmark + SNAT + ip rule + ip-route

由于涉及到对TCP连接的判断，一开始的想法，自然是往iptables上靠。而外网的话，尽管有些蹩脚，也勉强定义为从`0.0.0.0/0`中去除掉`192.168.0.0/16`,`172.16.0.0/12`,`10.0.0.0/8`,`127.0.0.1/32`,`255.255.255.255/32`这些子网这样的范畴，于是有了下面这样的方案：

```bash
# Mask packets need to be send via wg0
sudo iptables -t mangle -A wg_wg0 -d 255.255.255.255/32 -j RETURN
sudo iptables -t mangle -A wg_wg0 -d 127.0.0.1/32 -j RETURN
sudo iptables -t mangle -A wg_wg0 -d 192.168.0.0/16 -j RETURN
sudo iptables -t mangle -A wg_wg0 -d 172.16.0.0/12 -j RETURN
sudo iptables -t mangle -A wg_wg0 -d 10.0.0.0/8 -j RETURN
sudo iptables -t mangle -A wg_wg0 -p tcp -j MARK --set-mark 10086
sudo iptables -t mangle -A OUTPUT -j wg_wg0

# Re-write source ip
sudo iptables -A POSTROUTING -t nat -m mark --mark 10086 -j SNAT --to-source 10.253.0.2

# Set route for those packets
sudo ip route add default dev wg0 src 10.253.0.2 table 10086
sudo ip rule add fwmark 10086 table 10086
```

> 参考了StackExchange上的[这个](https://unix.stackexchange.com/questions/21093/output-traffic-on-different-interfaces-based-on-destination-port)讨论

可以理解为以下几个步骤：
- 使用iptables在mangle表的OUTPUT链上，将tcp链接附上标记为`10086`
- 使用策略路由ip rule方式匹配这些流量，使其用一张新的路由表（table 10086）来路由决策，使其发送到wg0设备
- 使用SNAT来改变数据包源地址

可能是受到了tailscaled的影响，在我的机器上使用这种方案，只能用一会，之后所有的连接都会出问题，又或者是http以及ssh连接正常而https链接不正常，比较诡异。从tcpdump中看，源ip也符合`wg0`接口的ip。鉴于没有调试出原因，且其SNAT的方式不太优雅，这种方案只能放弃。

# ip rule + ip-route

最终在浏览ip rule和ip route手册时，发现了一种不需要iptables的，比较优雅的方案。
让我们看看ip rule的参数：
```txt
Usage: ip rule { add | del } SELECTOR ACTION
       ip rule { flush | save | restore }
       ip rule [ list [ SELECTOR ]]
SELECTOR := [ not ] [ from PREFIX ] [ to PREFIX ] [ tos TOS ]
            [ fwmark FWMARK[/MASK] ]
            [ iif STRING ] [ oif STRING ] [ pref NUMBER ] [ l3mdev ]
            [ uidrange NUMBER-NUMBER ]
            [ ipproto PROTOCOL ]
            [ sport [ NUMBER | NUMBER-NUMBER ]
            [ dport [ NUMBER | NUMBER-NUMBER ] ]
ACTION := [ table TABLE_ID ]
          [ protocol PROTO ]
          [ nat ADDRESS ]
          [ realms [SRCREALM/]DSTREALM ]
          [ goto NUMBER ]
          SUPPRESSOR
SUPPRESSOR := [ suppress_prefixlength NUMBER ]
              [ suppress_ifgroup DEVGROUP ]
TABLE_ID := [ local | main | default | NUMBER ]
```

首先，ip rule本身的匹配规则中，支持基于`ipproto`来匹配，这样我可以用`ipproto tcp`来匹配tcp包。

接下来要解决匹配目标ip范围的匹配问题，我们有以下这些候选项：
- `oif STRING`：这里面有一个`oif`选项似乎可以根据数据包的出站interface来匹配，乍一眼看，我只需要用`oif wlp44s0`匹配我的无线网卡，甚至不需要去以蹩脚的方式去匹配目标ip范围。但文档里说`oif`只有在程序创建socket时绑定到了某个设备上时才能起作用，所以这个选项不管用。
  ```txt
              oif NAME
                    select the outgoing device to match. The outgoing
                    interface is only available for packets originating
                    from local sockets that are bound to a device.
  ```

- `to PREFIX`：方式也不太优雅，ip rule的`not`表达式只能在对整条规则起作用。我们无法做到 `ipproto tcp not to 192.168.0.0/16 not to 172.16.0.0/12 not to 10.0.0.0/8`这样的匹配。
- `table main`：使用`not tcp table main`直接跳到`main`表也是一种选择。但这种方式不适合我的情况，因为tailscale也创建了一些rule，这么做要么会把tailscale的规则忽略，要么会与tailscale产生关联。
  ```txt
  0:      from all lookup local
  5210:   from all fwmark 0x80000/0xff0000 lookup main
  5230:   from all fwmark 0x80000/0xff0000 lookup default
  5250:   from all fwmark 0x80000/0xff0000 unreachable
  5270:   from all lookup 52
  32766:  from all lookup main
  32767:  from all lookup default
  ```

最后选择了ip route的`throw`路由方案，它有点像iptables里的`RETURN`动作。如果被路由表里的`throw`类型的路由匹配到，那么将退出该路由表的搜索并假装发生了路由缺失，从而fallback到ip rule里的其他策略，这个策略就非常适合我的场景。
  ```txt
                throw - a special control route used together with policy
                rules. If such a route is selected, lookup in this table
                is terminated pretending that no route was found. Without
                policy routing it is equivalent to the absence of the
                route in the routing table. The packets are dropped and
                the ICMP message net unreachable is generated. The local
                senders get an ENETUNREACH error.
  ```

所以最终的脚本如下：
```bash
sudo ip route add default dev wg0 src 10.253.0.2 table 10086
sudo ip route add throw 192.168.0.0/16 table 10086
sudo ip route add throw 172.16.0.0/12 table 10086
sudo ip route add throw 10.0.0.0/8 table 10086
sudo ip rule add ipproto tcp table 10086
```

# 总结

之前配网的时候接触`ip rule`总有这种感觉，`ip rule`是个好东西，但是它的规则匹配似乎很弱，总会想用iptables set-mask的方式来实现复杂的规则，但是iptables写起来就总是很麻烦。现在看来，`ip rule`和`ip route`组合起来还是很强大的，能够实现很多的需求。

