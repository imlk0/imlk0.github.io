---
title: 'PXE无盘启动树莓派集群'
date: 2020-10-04T20:24:05+08:00
id: 64
aliases:
  - /blog/64/
categories:
  - Raspberry Pi
tags:
  - 树莓派
  - 路由器
  - NFS
  - 瞎搞
---

最近从同学那里拿到了几个闲置的树莓派，外加一个路由器和一块2T的硬盘，于是乎想用这些派来搭建一个简单的集群。但是发现SD卡实在是不够，遂尝试使用nfs的方式来启动树莓派。

实验中用到的东西主要有：

- 树莓派3B v1.2
- 刷有openwrt固件的路由器（竞斗云2.0）
- 挂载在路由器上的移动硬盘（U盘应该也可以，不过要足够大）
- 一张烧录了Raspberry Pi OS的SD卡（只在配置过程中会用到一次）
- 一条网线（连接派和路由器）
- 测试过程用的：HDMI转VGA线、USB键盘、USB鼠标

![树莓派3B](/images/blog/64/image-20201004200939893.png)

## 树莓派开启USB/network启动

为了让树莓派支持从nfs启动，我们需要给树莓派的OTP写入一个标志位。我们需要先准备一张烧录了Raspberry Pi OS的SD卡，插入树莓派启动。

首先进行系统更新，让树莓派更新到最新的bootloader

```sh
sudo apt update && sudo apt full-upgrade
```

增加启动选项，在下一次启动时，树莓派会根据该选项修改OTP（OTP的写入是一次性的，不可以改回去，但是在树莓派的启动顺序中，USB启动是排在SD卡之后的，因此并不会对实际使用造成影响）：

```sh
echo program_usb_boot_mode=1 | sudo tee -a /boot/config.txt
```

在重启之前，我们读取OTP，这是没有开启过网络启动的树莓派的输出结果：

```
pi@raspberrypi:~ $ vcgencmd otp_dump | grep 17:
17:1020000a
```

重启之后，会发现OTP相应位应该已经被修改：

```
pi@raspberrypi:~ $ vcgencmd otp_dump | grep 17:
17:3020000a
```

此时可以修改`/boot/config.txt`去掉`program_usb_boot_mode=1`选项

## 配置文件系统

在启动前，我们需要为树莓派准备系统文件。由于我们不需要运行桌面程序，而仅仅将树莓派作为服务器，所以我们选择了[DietPi](https://dietpi.com/)的系统镜像来部署，其实Raspberry Pi OS镜像的部署方式也大同小异。

下载后解压得到以下内容：

```
DietPi_RPi-ARMv6-Buster/
├── DietPi_RPi-ARMv6-Buster.img
├── hash.txt
└── README.md
```

我们需要先将img文件通过loop设备挂载到本机上，具体的方法可以在网上找到，挂载后可以看到这个img文件里包含两个分区：

```
NAME      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0       7:0    0  1015M  1 loop 
├─loop0p1 259:0    0   256M  1 part /run/media/imlk/boot
└─loop0p2 259:1    0 754.9M  1 part /run/media/imlk/rootfs
```

分区名称分别是`boot`分区和`rootfs`分区。boot分区存放的主要是启动阶段需要的`bootcode.bin`以及系统内核文件，该分区在Linux启动后一般会被挂载到`/boot`目录下。`rootfs`分区就更好理解了，就是被挂载到`/`的根文件系统。

#### 准备系统文件

我们准备了一块2T的移动硬盘，在上面划分了512G的ext4格式分区用来存储树莓派的根文件系统，在我们的演示中，我们将该分区挂载到了`/mnt/cluster/`。

为了便于管理，我们在该分区中创建一个名为`system`的目录，用来存放不同树莓派设备的文件，不同的树莓派设备的文件被放在它们的序列号所对应的子目录下（用序列号仅仅是为了区分设备而已，你也可以用别的名称）。例如我们当前的树莓派设备序列号是`000000008a4232c8`，则该设备的文件路径为`/mnt/cluster/system/000000008a4232c8`。

（序列号可以通过`cat /proc/cpuinfo`命令的`Serial`字段找到）

然后使用rsync命令将镜像的`rootfs`分区内容拷贝到子目录下的rootfs目录中（注意目录末尾的`/`不能忽略，否则语义不同）：

```sh
sudo rsync -a /run/media/imlk/rootfs/ /mnt/cluster/system/000000008a4232c8/rootfs/
```

接着，我们将`boot`分区的内容拷贝到rootfs目录下的boot子目录中（其实也可以放在一个单独的目录下，但是这样的话我们就还需要在`/etc/fstab`下配置一条`/boot`的nfs条目）：

```sh
sudo rsync -a /run/media/imlk/boot/ /mnt/cluster/system/000000008a4232c8/rootfs/boot/
```

为了方便，我们在rootfs的父目录下创建一个软链接，指向`rootfs/boot`:

```sh
sudo ln -s rootfs/boot /mnt/cluster/system/000000008a4232c8/boot
```

最终对应该设备的目录树如下：

```
root@g-dock:~# tree -L 2 /mnt/cluster/system
/mnt/cluster/system
└── 000000008a4232c8
    ├── boot -> rootfs/boot		# 对应boot分区
    └── rootfs					# 对应rootfs分区

3 directories, 0 files
```

上面的`boot`软链接对应了原始镜像中`boot`分区的内容，`rootfs`目录对应了原始镜像中`rootfs`分区的内容。

至此，一台树莓派设备的系统文件初始化完成。如果我们现在要新增一台树莓派，可以直接拷贝一份`000000008a4232c8`目录，命名为新树莓派的序列号。

## 配置路由器

#### 在路由器上挂载移动硬盘

我们使用一台竞斗云2.0作为路由设备，在它上面挂载移动硬盘。

测试速度如下：

```
root@g-dock:/etc/opkg# hdparm -Tt /dev/sda4 
/dev/sda4:
 Timing cached reads:   714 MB in  2.00 seconds = 356.74 MB/sec
 Timing buffered disk reads:  88 MB in  3.19 seconds =  27.63 MB/sec
```

```
root@g-dock:/etc/opkg# bonnie++ -n 0 -u 0  -f -b -d /mnt/data
Using uid:0, gid:0.
Writing intelligently...done
Rewriting...done
Reading intelligently...done
start 'em...done...done...done...done...done...
Version  1.98       ------Sequential Output------ --Sequential Input- --Random-
                    -Per Chr- --Block-- -Rewrite- -Per Chr- --Block-- --Seeks--
Name:Size etc        /sec %CP  /sec %CP  /sec %CP  /sec %CP  /sec %CP  /sec %CP
OpenWrt          1G           32.1m  56 13.4m  28           27.0m  28  96.3  31
Latency                       34156us     183ms               166ms     515ms

1.98,1.98,OpenWrt,1,1601667412,1G,,8192,5,,,32834,56,13675,28,,,27680,28,96.3,31,,,,,,,,,,,,,,,,,,,34156us,183ms,,166ms,515ms,,,,,,
```

（可选）开启硬盘禁止自动休眠（spin-down）

```
root@g-dock:~# hdparm -S 0 /dev/sda

/dev/sda:
 setting standby to 0 (off)
```

#### 配置PXE引导服务器

我们使用`dnsmasq`内置的的PXE引导服务来为树莓派实现网络启动的第一步。`dnsmasq`是一个常用的提供DHCP服务和DNS服务的进程。首先我们需要修改它的配置文件，让它在网络启动过程作为PXE引导服务器，并通过tftp协议为树莓派提供boot分区中的`bootcode.bin`和内核文件。

修改`/etc/dnsmasq.conf`内容如下：

```
log-facility=/var/log/daemon.log	# 指定日志文件输出路径
# port=0 							# 设定port=0会禁用dns服务，不需要配置
log-dhcp							# 在日志中显示dhcp请求信息
enable-tftp							# （关键）启动tftp服务
tftp-root=/mnt/cluster/tftpboot		# （关键）设定tftp服务的基础根目录
tftp-unique-root=mac				# （关键）设定用mac地址区分不同设备的根目录
pxe-service=0,"Raspberry Pi Boot"	# （关键）pxe服务相关配置
```

配置完后重启`dnsmasq`。

该配置文件中，`log-facility`指定日志文件输出路径，`log-dhcp`表示在日志中显示dhcp请求信息，开启这两者方便我们排除错误。我们还设定了`/mnt/cluster/tftpboot`作为基础根目录，同时设定`tftp-unique-root=mac`来为区分为不同设备提供的文件，该选项会自动在基础根目录后追加mac地址，例如mac地址为`b8:27:eb:42:32:c8`的设备所看到的目录为`/mnt/cluster/tftpboot/b8-27-eb-42-32-c8/`。

接下来我们在挂载的硬盘分区中创建`tftpboot`目录，并根据树莓派网口的mac地址，创建一个指向该设备boot分区内容的软链接：

```sh
sudo ln -s ../system/000000008a4232c8/boot/ /mnt/cluster/tftpboot/b8-27-eb-42-32-c8
```

最终`tftpboot`目录的结构如下：

```
root@g-dock:~# tree /mnt/cluster/tftpboot/
/mnt/cluster/tftpboot/
└── b8-27-eb-42-32-c8 -> ../system/000000008a4232c8/boot/

1 directory, 0 files
```

这样，树莓派启动时向`dnsmasq`查询文件，`dnsmasq`就会在`/mnt/cluster/tftpboot/b8-27-eb-42-32-c8/`中，即该设备的boot分区文件中查找。

至此，树莓派已经能够从路由器上加载内核文件并执行。

#### 配置nfs服务器

经过上一步，内核虽然可以成功启动，但是是无法挂载rootfs的，接下来，我们需要用nfs来提供rootfs。

在路由器上安装nfs-server

```
opkg update
opkg install nfs-kernel-server
```

配置`/etc/exports`文件，将我们之前在磁盘中准备的`system`目录暴露出去

```
root@g-dock:/mnt/cluster# cat /etc/exports 
/mnt/cluster/system   192.168.1.0/255.255.255.0(rw,sync,no_subtree_check,no_root_squash)
```

(注意括号中的选项不要写错，尤其是注意需要配置`no_root_squash`选项，否则nfs客户端无法以root用户身份执行操作)

启动nfs服务：（通常会使用portmap来搭配提供rpc，但是我们路由器上没有安装portmap，我们使用rpcbind替代）

```
root@g-dock:~# service rpcbind start
root@g-dock:~# service rpcbind enable
root@g-dock:~# service nfsd start
root@g-dock:~# service nfsd enable
```

可以再自己的电脑上测试能否挂载nfs：

```
[imlk@imlk-pc cluster]$ sudo mount -t nfs 192.168.1.1:/mnt/cluster/system/000000008a4232c8/rootfs ./system/
[imlk@imlk-pc cluster]$ tree -L 1 system/
system/
├── bin
├── boot
├── dev
├── etc
├── home
├── lib
├── lost+found
├── media
├── mnt
├── opt
├── proc
├── root
├── run
├── sbin
├── srv
├── sys
├── tmp
├── usr
└── var

19 directories, 0 files
```

可以看到上面我们成功将一台设备的rootfs通过nfs挂载到了我们的机器上（挂在失败的注意检查服务器`/etc/exports`中的配置，以及服务器的防火墙配置）

#### 最后一点点配置

下面的配置文件均指rootfs目录下的文件，而不是路由器自身的文件

##### 配置内核命令行`/boot/cmdline.txt`

我们需要配置内核命令行选项，让内核从nfs挂载rootfs。

首先在路由器上查看rootfs中的`/boot/cmdline.txt`文件：

```
root@g-dock:~# cat /mnt/cluster/system/000000008a4232c8/boot/cmdline.txt 
console=serial0,115200 console=tty1 root=PARTUUID=907af7d0-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet net.ifnames=0
```

删除`root=`和`rootfstype=`的内容，改成`root=/dev/nfs`和`nfsroot=192.168.1.1:/mnt/cluster/system/000000008a4232c8/rootfs,vers=3,proto=tcp`，后者是指定rootfs在nfs服务器上的路径。需要注意的是`vers=3`这个配置，在有些文献中配置 的是`vers=4.1`，但是实测dietpi的内核似乎不支持挂载4.1版本的nfs，改成`vers=3`后就成功了。

改完之后内容如下：

```
root@g-dock:~# cat /mnt/cluster/system/000000008a4232c8/boot/cmdline.txt 
console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.1.1:/mnt/cluster/system/000000008a4232c8/rootfs,vers=3,proto=tcp rw ip=dhcp rootwait elevator=deadline
```

##### 配置自动挂载`/etc/fstab`

由于我们配置了内核启动时从nfs获取rootfs，`/etc/fstab`里不再需要挂载`/`。我们删除rootfs里`/etc/fstab`文件中关于`/`和`/boot`的挂载条目：要删除的条目类似于如下内容：

```
PARTUUID=907af7d0-02 / auto noatime,lazytime,rw 0 1
PARTUUID=907af7d0-01 /boot auto noatime,lazytime,rw 0 2
```

##### 配置网络接口初始化`/etc/network/interfaces`

这部分和init进程初始化网络接口有关系，它会读取`/etc/network/interfaces`中的配置对网络接口进行初始化。由于我们在加载rootfs时已经初始化了eth0，这里我们不能再对eth0进行重新初始化，否则nfs会中断，导致init进程提示`a start job is running for the raise network`然后block住。

我们需要注释掉和eth0有关的条目：

```
# Ethernet
#allow-hotplug eth0
#iface eth0 inet dhcp
#address 192.168.0.100
#netmask 255.255.255.0
#gateway 192.168.0.1
#dns-nameservers 9.9.9.9 149.112.112.112
```

### 启动

拔掉树莓派的SD卡，用网线连接树莓派的网口和路由器，如果有HDMI和键盘也都可以接上，然后通电。等待10秒左右，树莓派会fallback到USB/Network方式启动。

查看dnsmasq的日志文件，第一阶段树莓派向dnsmasq请求`bootcode.bin`：

![image-20201004200646054](/images/blog/64/image-20201004200646054.png)

第二阶段向dnsmasq请求内核和其它文件：

![image-20201004200744633](/images/blog/64/image-20201004200744633.png)

接下来内核会初始化dhcp客户端，然后通过nfs挂载rootfs。

成功启动：

![IMG_20201004_201311](/images/blog/64/IMG_20201004_201311.jpg)

## 故障排除

- 内核启动后卡住，显示类似于下面的内容

  ```
  IP-Config: Complete:
  ...
  random: crng init done
  ```

  原因：内核挂载rootfs失败，请检查`boot/cmdlime.txt`中填写的内容

- 启动或关机时卡卡住，屏幕上的systemd日志显示`[***] A start job is running for LSB: raise network interfaces`

  `/etc/network/interfaces`配置问题，由于rootfs是通过nfs挂载的，因此系统启动后不应改变`eth0`接口的状态，否则已挂载的根文件系统会宕掉。

  

## 相关文献

- 树莓派的两种USB启动模式

  https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/usb.md

- 树莓派启动顺序

  https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/bootflow.md

- 树莓派配置网络启动教程(official)

  https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net_tutorial.md

- 预启动执行环境（PXE）

  https://zh.wikipedia.org/wiki/%E9%A2%84%E5%90%AF%E5%8A%A8%E6%89%A7%E8%A1%8C%E7%8E%AF%E5%A2%83