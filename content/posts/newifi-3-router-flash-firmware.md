---
title: 'newifi 3 路由器刷padavan固件'
date: 2020-03-12T17:26:11+08:00
id: 63
aliases:
  - /blog/63/
categories:
  - Router
tags:
  - 路由器
  - 固件
  - 瞎搞
  - padavan
---

新路由器到了两星期了，期间总是出现突然wan网络不通的情况，而且信号也没有上一台强（严重影响蹲坑时玩手机的体验）。参考网友们的建议，准备给newifi3刷老毛子固件玩。

### 连接路由器

这里连接路由器有两种方法

- telnet

  这玩意虽然默认没有开ssh端口，竟然默认开了telnet，把我给看傻了，直接telnet连上去就好了：

  ```
  [imlk@imlk-pc ~]$ telnet 192.168.99.1
  Trying 192.168.99.1...
  Connected to 192.168.99.1.
  Escape character is '^]'.
   ================================================================
   |                   Welecome to PandoraBox !                   |
   |                    Copyright 2013-2016                       |
   |              D-Team Technology Co.,Ltd. ShenZhen             |
   ================================================================ 
  newifi_B4C7 login: root
  Password:
  ```

- ssh

  上面说过，官方固件没开ssh，但是访问一下这个链接：

  http://192.168.99.1/newifi/ifiwen_hss.html

  看到success后你会发现奇迹般地ssh也开放了。

上了路由器先看看，mips架构，可能是基于PandoraBox的固件改的吧，登录文字里写的是PandoraBox。

比较有意思的是`/dev/root`挂载到`/rom`，`/dev/mtdblock5`挂载到`/overlay`，然后似乎是结合这俩整了个overlayfs直接给挂载到`/`。得了，又是没见过的操作：

```
overlayfs:/overlay on / type overlayfs (rw,noatime,lowerdir=/,upperdir=/overlay)
```

### breed

这里下载的https://breed.hackpascal.net/是一个固件，需要解锁路由器才能刷入。breed的作者提供了一种加载内核模块`newifi-d2-jail-break.ko`刷入的方法，用这种方法似乎是“免解锁”的，具体作者的帖子在这：https://www.right.com.cn/forum/thread-342918-1-1.html



解压后用scp上传到路由器的`/tmp/`目录加载内核模块

```
insmod '解压后的.ko文件'
```

之后会卡住一段时间重启，重启后还是官方固件。



接下来要进入恢复模式，断电后按住reset键插入电源启动，注意需要用数据线直连路由器。

![Breed web 恢复控制台](/images/blog/2020-03-12 23-13-30屏幕截图.png)



### padavan

这里我选择的是hiboy制作的padavan固件

相关帖子：https://www.right.com.cn/forum/thread-2110335-1-1.html

下载地址：https://opt.cn2qq.com/padavan/

固件更新界面选择固件，安装该固件即可，很简单。

![](/images/blog/2020-03-12 23-20-23屏幕截图.png)

重启后进入192.168.123.1就是熟悉的界面了，默认账号密码是admin和admin。比较可惜的是它只认440M内存，而总内存应该是512M的。最后测试信号强度要明显比原来的好，一些没网络的角落也能有2.4G信号了。

![padavan界面](/images/blog/2020-03-13 12-57-28屏幕截图.png)

后面广告拦截啥的就看个人喜好啦。