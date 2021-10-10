---
title: 在AVD_7.1_x86 emulator上安装微信
date: 2019-06-13T16:35:07+08:00
id: 51
aliases:
  - /blog/51/
categories: 
  - Android
tags: 
  - Android
  - AVD
  - Xposed
  - 瞎搞
---


### 起因
好久没有写博客了，并不是其中没有折腾2333，作业太多好多事情都没写（其实就是懒）

那啥，手头有两台手机，一台太烂但是7.1.1 root过（曾经的主力机，依然坚挺），另一台是7.0 垃圾索大法，au定制机，没法root。
前一台没有运动传感器，想拿来计步都不行，第二台有传感器但是不能root，就不能微信刷步数啦23333（真是贪婪的人类）

寻思着在avd上装微信刷步数。于是有了下面的折腾记录，同时也是做个笔记，避免以后绕弯路，毕竟，博客都是给以后的自己看的23333。

### AVD_4.4
原先我就有一台Android 4.4的虚拟设备，已经root而且装了xp，接着安装微信和模块打算开刷的时候，我点开微信，悲剧发生了，闪退！！！！
看一下logcat，傻逼微信在新版用了一个sdk21之后才加入的函数，但是自己又声称最低支持Android4.4，我真是dnlm！！！！


没办法，看来4.4上是没法折腾的，索性再开一台Android 7.1的AVD吧，说不定以后还要用上呢。

### AVD_7.1
怎么安装这个就不用我多说啦，困难的地方主要就是root和安装微信这两个。

#### root
root的话，就参考这个了：
把supersu官网的那一套东西下载下来（虽然各个版本方案不同，但是文件都在里头）
[android emulator 获取 Root权限](https://blog.csdn.net/luvsnow/article/details/79963025)

注意启动的时候加上`-writable-system`
可惜的是，这种root好像是短时期的，不能按电源键重启设备，也不能adb reboot重启虚拟设备，这样再开之后root就会没。不过恢复也很简单，只要再走一遍
- adb root
- adb remount
- adb shell
- su --install
- su -d&
- setenforce 0
然后授权管理里面root又有啦

#### 装微信
装微信可没那么简单，毕竟这里可是AVD_x86，要是简单的话你也不会来这里了。

微信只给了arm的lib，但是AVD普遍是x86的，会发生安装不上提示ABI不兼容的情况，对于这种问题有两个解决办法：
- 安装arm的AVD（×）
	缺点：不是一般的慢，看不到开机完成
- ARM-Translation（√）
	这个东西似乎是intel搞个一个闭源的层，能把apk里的arm用的so库在运行时动态地转换成x86的指令，所有x86的Android设备里都有这个，Android-x86和Genymotion据说都内置这个东西，总之牛逼就对了。

##### ARM-Translation
先贴一堆参考前人的资料
1. [移动测试基础 Android 模拟器 Genymotion 安装配置与 ARM 支持](https://testerhome.com/topics/14231)
1. [Android Emulator - INSTALL_FAILED_NO_MATCHING_ABIS: Failed to extract native libraries, res=-113](https://android.stackexchange.com/questions/179482/android-emulator-install-failed-no-matching-abis-failed-to-extract-native-lib)
1. [如何打开Android X86对houdini的支持](https://blog.csdn.net/Roland_Sun/article/details/49735601)
1. [Android模拟器知识以及改造](https://blog.csdn.net/wangkai0681080/article/details/79523003)
1. [Github/Rprop/libhoudini](https://github.com/Rprop/libhoudini)
1. [Android-X86集成houdini(Arm兼容工具)](http://baba.zhaoxiuyuan.com/2017/11/126_android_x86_houdini/)

资料这么多，我来梳理一下下吧：
要使用这个ARM-Translation其实不麻烦。主要下面几个步骤：
- 改`build.prop`里的`ro.product.cpu.abilist`和`ro.product.cpu.abilist32`为`x86,armeabi-v7a,armeabi`，骗过包安装器，让它能把微信装上(参考第4篇文章)
- 改`default.prop`里的`ro.dalvik.vm.native.bridge=0`为`ro.dalvik.vm.native.bridge=libhoudini.so`，开启系统内的NativeBridge(参考第4篇文章)
	这里必须说一下，这个`default.prop`不在`system.img`里面，在`ramdisk.img`里面，`ramdisk.img`是只读的，只在启动的时候读一次到内存里。所以对`default.prop`的修改重启后会丢失，唯一的办法是手动编辑一个`ramdisk.img`，然后用emulator的`-ramdisk`选项指定修改后的`ramdisk.img`文件。

	编辑的方法也不难，参考这个里面的第二种方法[制作/解压android ramdisk.img镜像](https://blog.csdn.net/linuxdriverdeveloper/article/details/8124319)
	- 从SDK目录里找到ramdisk.img，备份一份到自己的avd目录里，
	- 用gunzip解压它，再用cpio解包到一个目录里
	- 在这目录里找到`default.prop`进行修改
	- 注意回package的时候，不要用cpio打包，可能会有问题导致开机不了，用`mkbootfs ./你之前解包到的目录 | gzip > ramdisk-new.img`制作修改后的镜像（可以从这下载mkbootfs https://github.com/shenyuanv/mkboot-tools ）
	- 最后的`ramdisk-new.img`就是修改过的`ramdisk.img`了，在启动avd时用emulator的`-ramdisk`选项指定它即可。

- 第3篇文章里面设置里那个叫`Enable native bridge`的选项我一直没有找到，它说效果只是`persist.sys.nativebridge`从0改成了1，保险起见，我在`build.prop`里加了`persist.sys.nativebridge=1`
- 执行enable_nativebridge
	这几篇文章里都提到了`enable_nativebridge`这个东西，但是我找了一番，我的AVD里面没有这个脚本啊啊，真的服了，为什么google做了这个东西又不拿出来给我们用呢？？？？咱啥也不知道，咱也不敢问
	
	不过还好，在万能的github上面找到了一段`enable_nativebridge`，大概读一读能发现，恰好是Android7用的，而且考虑了各种情况，甚至还可以在线下载文件（显然访问不了，不过有办法解决的），[https://gist.github.com/41a5d8ba498ceecca28e9d1069a32ede](https://gist.github.com/41a5d8ba498ceecca28e9d1069a32ede)，访问不了gist的可以用google快照看。方便大家我就贴在下面了：
```sh
#!/system/bin/sh

PATH=/system/bin:/system/xbin

houdini_bin=0
dest_dir=/system/lib$1/arm$1
binfmt_misc_dir=/proc/sys/fs/binfmt_misc

if [ -z "$1" ]; then
	if [ "`uname -m`" = "x86_64" ]; then
		v=7_y
		url=http://goo.gl/SBU3is
	else
		v=7_x
		url=http://goo.gl/0IJs40
	fi
else
	v=7_z
	url=http://goo.gl/FDrxVN
fi

if [ -s /system/lib$1/libhoudini.so ]; then
	log -pi -thoudini "found /system/lib$1/libhoudini.so"
elif [ -e /system/etc/houdini$v.sfs ]; then
	mount /system/etc/houdini$v.sfs $dest_dir
else
	if mountpoint -q $dest_dir; then
		kill -9 `fuser -m $dest_dir`
		umount -f $dest_dir
	fi
	mkdir -p /data/arm
	cd /data/arm
	while ! mount houdini$v.sfs $dest_dir; do
		while [ "$(getprop net.dns1)" = "" ]; do
			sleep 10
		done
		wget $url -cO houdini$v.sfs && continue
		rm -f houdini$v.sfs
		sleep 30
	done
fi

[ -s /system/lib$1/libhoudini.so ] || mount --bind $dest_dir/libhoudini.so /system/lib$1/libhoudini.so

# this is to add the supported binary formats via binfmt_misc

if [ ! -e $binfmt_misc_dir/register ]; then
	mount -t binfmt_misc none $binfmt_misc_dir
fi

cd $binfmt_misc_dir
if [ -e register ]; then
	[ -e /system/bin/houdini$1 ] && dest_dir=/system/bin
	# register Houdini for arm binaries
	if [ -z "$1" ]; then
		echo ':arm_exe:M::\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\x28::'"$dest_dir/houdini:P" > register
		echo ':arm_dyn:M::\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\x28::'"$dest_dir/houdini:P" > register
	else
		echo ':arm64_exe:M::\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xb7::'"$dest_dir/houdini64:P" > register
		echo ':arm64_dyn:M::\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\xb7::'"$dest_dir/houdini64:P" > register
	fi
	if [ -e arm${1}_exe ]; then
		houdini_bin=1
	fi
else
	log -pe -thoudini "No binfmt_misc support"
fi

if [ $houdini_bin -eq 0 ]; then
	log -pe -thoudini "houdini$1 enabling failed!"
else
	log -pi -thoudini "houdini$1 enabled"
fi

[ "$(getprop ro.zygote)" = "zygote64_32" -a -z "$1" ] && exec $0 64

exit 0
```
把这个脚本放到avd里的`/system/bin/`目录下，记得把`log -pi -thoudini`改成`echo`方便我们最后观察是否成功了。

###### houdini.sfs
其中最核心的是那个houdini.sfs文件，当然各个Android版本的文件名不太一样，国内要下载的话，第6篇文章里的作者给了短网址还原的办法，不过我还发现另外一个仓库 https://github.com/Rprop/libhoudini ，这里面各个版本的sfs文件都有，阅读脚本发现，可以**手动下载这个文件**然后放到`/system/etc/`下面。

这个sfs文件其实是`squashfs`格式的一个影像，脚本里把它挂载到`/system/lib/arm`文件夹里（64位的情况是另一个文件夹，这里的描述都以x86为准，x86_64看上面的脚本进行变通）。

**一些意外**
- 中途mount这个houdini.sfs的过程发生了一些意外，首先提示`No such file or directory`，手动`mkdir /system/lib/arm`解决了这个问题。

- 之后说`mount: losetup failed 1`，改为手动mount加上`-v`选项后说
	```
	try '/system/etc/houdini7_x.sfs' type 'ext3' on '/system/lib/arm/'
	```
	显然它把我文件格式搞错了，这个sfs文件应该是`squashfs`而不是`ext3`，加`-t`选项强制指定`squashfs`格式后告诉我`No such device`，你说你马呢，我文件好端端在这你告诉我没有。无奈之下想到了`strace`大法，给这条命令前加上`strace`，查看系统调用过程，发现其中调用了`mount()`函数：
	```
	mount("/system/etc/houdini7_x.sfs", "/system/lib/arm/", "squashfs", MS_SILENT, NULL) = -1 ENODEV (No such device)
	```
	man查mount()的手册发现，`ENODEV`表示不支持的文件系统格式，也就是说**这个avd它丫的不支持`squashfs`这个文件系统**，网上说可以在编译的时候加选项，但是显然我们是不会去编译的，费力不讨好。解决办法很简单，在宿主机上mount一下，把里面的文件拿出来`adb push`到avd的`/system/lib/arm`这个目录，大功告成。

- 之后还有个
	```
	mount --bind $dest_dir/libhoudini.so /system/lib$1/libhoudini.so
	```
	又失败了（Android终端里的命令好像就没几个好使的），目的主要是把`libhoudini.so`从`/system/lib/arm`文件夹引到`/system/lib`下面去，这个用`ln -s`搞一下就好。

这么搞一通，终于等来了输出`houdini enabled`。至此`houdini`就算是迁进去了。

##### 装微信
微信还是那样装，打开也能登陆，看起来甚至没有任何问题，但是打开微信小程序的时候就出现问题了，直接崩掉。
logcat里冒出
```
houdini : [17913] Unsupported feature (ID:0x20e000b2).
```
在这之前的一个日志是houdini加载了微信里面的一个`libj2v8.so`文件，也许是因为这个文件里面的指令有点特殊所以崩的吧。

上网找了找，发现不少人遇到类似的这种`Unsupported feature`问题，尝试过ida开`libhoudini.so`找这个字符串，发现这样的错误一共有六类，字符串好像是`Unsupported feature (ID:0x20e%05x)`，也就是说后面的`0x000b2`是变化的，但是字符串引用的地方没找到，因为ida反汇编的时候很多函数没有反汇编成功，再加上我ida用的不太熟，就没看了。最后瞅了一眼`houdini.sys`里面有个`houdini`可执行文件，执行一下输出：
```
[18097] 
[18097] Please don't use this program directly!
[18097] Use to check version only.
[18097] Usage: --version        output version information and exit!
[18097] 
```
看了一下我的--version输出是`Houdini version: 6.1.2d_x.48748`。它强调`don't use this program directly`，我就纳闷了，难不成这个程序除了输出version，里面还有东西？？？
索性拿ida开了一下，不出我所料，里面甚至有完整的`libhoudini.so`里面的内容，关键是这个文件ida反汇编得比较完善，按字符串找出错地方，发现是落入了一个switch语句的default区域，无奈代码太复杂，看不懂，放弃了。

##### 现有的其它方案

参考了现有的Android x86项目，发现它也使用到了houdini这个东西来实现arm架构支持，在它的Android7.1.1(sdk 25)版本中，同样也发现了`enable_nativebridge`这个脚本文件，在pc上u盘启动Android x86能够完美打开微信小程序，但是奇怪的是，根据脚本语句，它内部使用的不是对应的houdini7_x，而是houdini6_y，下面贴出`enable_nativebridge`的内容：

```shell
#!/system/bin/sh

PATH=/system/bin:/system/xbin

houdini_bin=0
dest_dir=/system/lib$1/arm$1
binfmt_misc_dir=/proc/sys/fs/binfmt_misc

cd /data/arm
if [ -e /system/lib$1/libhoudini.so ]; then
	log -pi -thoudini "found /system/lib$1/libhoudini.so"
elif [ -e /system/etc/houdini$1.sfs ]; then
	busybox mount /system/etc/houdini$1.sfs $dest_dir
else
	if mountpoint -q $dest_dir; then
		kill -9 `fuser -m $dest_dir`
		umount -f $dest_dir
	fi
	while ! busybox mount houdini$1.sfs $dest_dir; do
		while [ "$(getprop net.dns1)" = "" ]; do
			sleep 10
		done
		if [ -z "$1" ]; then
			[ "`uname -m`" = "x86_64" ] && url=http://goo.gl/Knnmyl || url=http://goo.gl/JsoX2C
		else
			url=http://goo.gl/n6KtQa
		fi
		wget $url -cO houdini$1.sfs && continue
		rm -f houdini$1.sfs
		sleep 30
	done
fi


# if you don't see the files 'register' and 'status' in /proc/sys/fs/binfmt_misc
# then run the following command:
# mount -t binfmt_misc none /proc/sys/fs/binfmt_misc

# this is to add the supported binary formats via binfmt_misc

if [ ! -e $binfmt_misc_dir/register ]; then
	mount -t binfmt_misc none $binfmt_misc_dir
fi

cd $binfmt_misc_dir
if [ -e register ]; then
	[ -e /system/bin/houdini$1 ] && dest_dir=/system/bin
	# register Houdini for arm binaries
	if [ -z "$1" ]; then
		echo ':arm_exe:M::\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\x28::'"$dest_dir/houdini:P" > register
		echo ':arm_dyn:M::\\x7f\\x45\\x4c\\x46\\x01\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\x28::'"$dest_dir/houdini:P" > register
	else
		echo ':arm64_exe:M::\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xb7::'"$dest_dir/houdini64:P" > register
		echo ':arm64_dyn:M::\\x7f\\x45\\x4c\\x46\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x03\\x00\\xb7::'"$dest_dir/houdini64:P" > register
	fi
	if [ -e arm${1}_exe ]; then
		houdini_bin=1
	fi
else
	log -pe -thoudini "No binfmt_misc support"
fi

if [ $houdini_bin -eq 0 ]; then
	log -pe -thoudini "houdini$1 enabling failed!"
else
	log -pi -thoudini "houdini$1 enabled"
fi

[ "$(getprop ro.zygote)" = "zygote64_32" -a -z "$1" ] && exec $0 64

exit 0
```

之后有尝试将houdini6_x安装到模拟器（选择x而不是y是因为x86的avd模拟器是32位的而不是64位）中，情况比houdini7_x要糟糕，这次是大概意思是是模拟器缺少x86的某些feature，程序都不能跑起来了，具体情况没有再深究了，后继想要继续弄的话，我想，可以从这个方面继续考虑。另外，houdini的原理可以探究一番，比如试试替代品什么的

##### 放弃装微信

似乎模拟器里微信开不了小程序是现在的一种通病，夜神啥的也开不了，据说得上旧版本微信，我这里尝试安装微信7.0前的最后一个版本，但是登录之后就一直给我闪退了，日志也啥都没，emmmm，比较烦躁。

最后结局是：老老实实买新手机刷步数吧！

### 其它
#### INSTALL_FAILED_CONTAINER_ERROR
如果adb安装微信的时候提示`INSTALL_FAILED_CONTAINER_ERROR`，不是网上说的那种因为`Manifest.xml`里面写的安装位置不对的原因，多半是一些玄学问题，只要在`adb install`加上`-r`这个选项就好了。


