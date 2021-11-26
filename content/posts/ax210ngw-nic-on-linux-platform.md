---
title: '吃螃蟹-在Linux上用上AX210NGW网卡'
date: 2020-12-11T15:34:07+08:00
id: 67
aliases:
  - /blog/67/
categories:
  - Linux
tags:
  - iwlwifi
  - ax210
  - 瞎搞
---

最近把一块1T的垃圾机械硬盘拿去换新了，分区后发现还留有不少的空间，再加上最近有挂byrbt做种的需求，于是乎把它拿来当移动硬盘挂bt啦。无奈主力电脑出厂自带的那块网卡实在是太垃圾了，根本过不了200Mbps。同学推荐上车AX200，搜了一下，50+￥左右，不算太贵。又正好看到Intel出了新款的AX210，好家伙，Wi-FI 7都给整上了，本着买新不买旧的原则，于是乎70+大洋某宝剁手买下了;)

买回来换上去一看，Windows下去官网装一个wifi驱动和一个蓝牙驱动就能用了。但是换到Linux下，发现根本识别不了网卡，啊这就很淦了，dmesg也没有看到有价值的信息，于是花几天时间查了查资料，算是把这个问题解决了，这里做个记录。

## 系统版本

首先我使用的发行版是Manjaro，内核版本是`5.4.80-2-MANJARO`，因此这篇文章不一定能够解决你的问题，但是排查过程可能会有所帮助。

## wifi问题

其实Linux内核中对AX210系列早就有支持了，关于AX210的[提交](https://github.com/torvalds/linux/commit/d151b0a2efa128cb4f643b11baf54b1e4de2c528#diff-9161e5dc4fbda717a6c0f43490cab079fffa987b7a5cf5831de396bcfb5ae01eR244)可以追溯到两年前，按道理相应的支持应该已经到位了，这就让我很迷惑。

1. 首先看了下`dmesg`的日志，里面并没有找到相关的信息

2. 执行`lsmod | grep iwlwifi`

   并没有看到输出，因此这里可以知道的是，`iwlwifi`模块并没有被加载，查阅[资料](https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi)发现，这个网卡属于Intel的比较新的型号，对应的驱动是一个叫`iwlwifi`的模块。于是执行下面的命令加载这个模块

   ```
   modprobe iwlwifi
   ```

   再次执行`lsmod | grep iwlwifi`发现模块现在已经被加载上了，`dmesg`里面出现了这样的内容：

   ```
   [    2.410221] cfg80211: Loading compiled-in X.509 certificates for regulatory database
   [    2.451194] cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
   [    2.486819] Intel(R) Wireless WiFi driver for Linux
   [    2.486820] Copyright(c) 2003- 2015 Intel Corporation
   ```

   按照传统功夫点到为止，驱动也加载了应该是能上网了，但是爷还是没法用wifi。

3. firmware问题？

   上面的那份资料所在的页面里还提供了每个型号对应的固件的下载，目前最新的是AX201，还没有AX210的固件。不过文中指出新的固件可以在[linux-firmware.git](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git)这里找到，其中有一个叫做[iwlwifi-ty-a0-gf-a0-59.ucode](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/iwlwifi-ty-a0-gf-a0-59.ucode?id=7eb7fda50e9aa554c6bfafdd456e6c2ea54f6163)的文件引起了我的注意，根据AX210的代号即为TyphoonPeak，大胆推断这个就是AX210对应的固件。

   linux-firmware.git中的固件不在GPL LICENSE的覆盖范围中，并且是以二进制的形式发布的，一般是默认用包管理器就安装了的（在manjaro中，包名为linux-firmware）。

   在本机上对应的目录为`/lib/firmware/`，在该目录下，我找到了一份`iwlwifi-ty-a0-gf-a0-59.ucode`文件，末尾是59是版本号

   ![image-20201211172348572](/images/blog/67/image-20201211172348572.png)

   说明我的电脑上是有固件的，没有的话，`git clone`下来拷贝一份`.ucode`文件到你电脑上就行了

   iwlwifi版本问题？

   执行：

   ```
   modinfo iwlwifi | grep firmware
   ```

   可以看到iwlwifi支持的所有固件，如果里面没有类似于`iwlwifi-ty-a0-gf-a0-60.ucode`这样的（版本号似乎不受影响，如果输出中是版本号60，也可以用59的firmware文件），说明你的iwlwifi可能太老了，老到还不知道AX210的存在呢，你需要更新iwlwifi。

4. iwlwifi问题？

   我面临的情况是，iwlwifi版本支持AX210，firmware也存在。也试过更新内核版本带动iwlwifi模块的更新，但是都没有效果。

   最后我看到了这么一个mail list：https://lore.kernel.org/linux-wireless/iwlwifi.20201202143859.a06ba7540449.I7390305d088a49c1043c9b489154fe057989c18f@changeid/T/#u

   这里提到Intel缺失了一些AX210不能被识别的原因是他们漏了加上部分`subsytem device ID`了。

   用`lspci -k`查看，我的这块AX210`vendor id`和`subsytem device ID`分别是[0x2725: 0x0024]，正好在遗漏的范围内：

   ![image-20201211165048156](/images/blog/67/image-20201211165048156.png)

   那么两个办法，一是升级kernel到最新的版本，提交是2020年12月3日和入的，5.10-rc7版本的内核已经包含了这个修复，考虑到新内核bug还是很多的（之前试过5.10-rc5版本无法usb共享上网）。因此采取了第二种办法，自己编译iwlwifi，然后把这个patch打上就行了。

   这里我们不能直接用aur里提供的iwlwifi和iwlwifi-next，这两个编译过程中都会出错，原因是不同版本内核头文件不一致导致一些函数找不到。但是我们可以下载[backport-iwlwifi.git](https://git.kernel.org/pub/scm/linux/kernel/git/iwlwifi/backport-iwlwifi.git)的源码来编译

   ```
   git clone https://git.kernel.org/pub/scm/linux/kernel/git/iwlwifi/backport-iwlwifi.git
   cd backport-iwlwifi
   ```

   mail list中提到了三个patch，我们一并给打上。

   首先下载patch文件：

   ```
   wget https://github.com/torvalds/linux/commit/9b15596c5006d82b2f82810e8cbf80d8c6e7e7b4.patch
   wget https://github.com/torvalds/linux/commit/568d3434178b00274615190a19d29c3d235b4e6d.patch
   wget https://github.com/torvalds/linux/commit/5febcdef30902fa870128b9789b873199f13aff1.patch
   ```

   打patch：在源码目录下对三个patch分别执行

   ```
   patch -Np1 -i <你下载的patch文件路径>
   ```

   正确输出结果类似如下：

   ![image-20201211170418845](/images/blog/67/image-20201211170418845.png)

   编译并安装

   ```
   sudo make && sudo make install
   ```

   我这里过程比较顺畅，编译时没有遇到问题，新的模块安装到了`/lib/modules/5.4.80-2-MANJARO/updates/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko.xz`这里

   接下来启用新的iwlwifi模块

   ```
   sudo modprobe -r iwlwifi && sudo modprobe iwlwifi
   ```

   然后就是检查dmesg输出：

   ![image-20201211170754645](/images/blog/67/image-20201211170754645.png)

   发现wlp1s0这个interface已经活了，很快啊，然后就是一个连wifi，一个看速率：

   ![image-20201211171018130](/images/blog/67/image-20201211171018130.png)

   从200Mb/s变成300Mb/s了

   好，很有精神

## 蓝牙


目前蓝牙问题还没有得到解决，[这个提交](https://github.com/torvalds/linux/commit/875e16759005e3bdaa84eb2741281f37ba35b886)将对AX210 Bluetooth的支持添加到了内核中，但是会报一个错误：

```plaintext
[  184.585416] Bluetooth: hci0: Reading Intel version information failed (-22)
```

已经有老哥在跟进这个bug了：

https://www.spinics.net/lists/linux-bluetooth/msg89107.html


看来还是等新版内核吧



## 相关文档

1. Linux Wireless - Intel - 固件列表

   https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi

2. 从backport-iwlwifi编译iwlwifi模块

   https://vampire.ink/desktop/compileiwlwifi.html

   