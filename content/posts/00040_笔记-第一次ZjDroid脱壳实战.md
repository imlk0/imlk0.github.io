---
title: '[笔记]第一次ZjDroid脱壳实战'
date: 2018-04-28 00:05:10
id: 40
categories:
	- 笔记
tags:
	- 杂文
	- 笔记
---


看了那么多逆向破解的文章，总得来点实战的了，正所谓实践出真知嘛。

拜读了姜维大神的[「Android中Xposed框架篇---基于Xposed的一款脱壳神器ZjDroid工具原理解析」](https://blog.csdn.net/jiangwei0910410003/article/details/52840602)，准备来个应用动手试试了，想起我自己之前有个应用恰好是大数字加固的，于是想试试破自己的应用。
(纯粹是个人黑历史，就不贴应用链接了)。


### 环境

我手头的设备是版本是 Android7.1.2 电脑上也有Android4.4版本的模拟器（Android Emulator，已root和刷入Xposed，不知道怎么手动给模拟器刷root的同学参考这个[https://android.stackexchange.com/questions/171442/root-android-virtual-device-with-android-7-1-1](https://android.stackexchange.com/questions/171442/root-android-virtual-device-with-android-7-1-1)）


### 准备

首先嘛，当然是要下载大名鼎鼎的ZjDroid模块了，这个脱壳工具是基于Xposed模块的，看了下该项目的github，似乎并没有给出ZjDroid现成的apk安装包，网上虽然是有找，但我还是选择自己手动编译了一下，

clone
导入AS

在解决了~几个问题~很多个问题以后总算是编译成功了。


**主要是为了解决导入库的问题和`multidex`的问题（为了支持低sdk版本的设备）**

**也算是学习了**


### 在脱壳的边缘试探

把编译好的apk装进我的手机（Android 7.1.2），激活模块重启，连上电脑，按照教程里的方法，启动俩`cmd`一个用来看`logcat`输出，一个用来发送广播执行指令，

试了一个：
查看dex信息
```
am broadcast -a com.zjdroid.invoke --ei target 18881 --es cmd '{action:dump_dexinfo}'
```
`logcat`输出是
```
04-27 21:00:19.798 12563 12563 D zjdroid-shell-com.imlk.BlackAndWhite: the cmd = dump_dexinfo
04-27 21:00:19.805 12563 13323 D zjdroid-shell-com.imlk.BlackAndWhite: The DexFile Infomation ->
04-27 21:00:19.805 12563 13323 D zjdroid-shell-com.imlk.BlackAndWhite: filepath:/data/app/com.imlk.BlackAndWhite-1/base.apk mCookie:-1
04-27 21:00:19.807 12563 13323 D zjdroid-shell-com.imlk.BlackAndWhite: End DexFile Infomation
```

似乎有什么奇奇怪怪的地方。。
`mCookie`的值是`-1`，不过看教程里面好像是一串没有规律的数字哇。心想可能是大数字又升级了，这种方案脱壳可能不能奏效。


不管了，继续试试：
```
 am broadcast -a com.zjdroid.invoke --ei target 8880 --es cmd '{"action":"backsmali","dexpath":"/data/app/com.imlk.BlackAndWhite-1/base.apk"}'

```

WTF!
程序退出了！
看下`logcat`里的输出
```
04-27 22:16:56.475 18342 18342 D zjdroid-shell-com.imlk.BlackAndWhite: the cmd = backsmali
04-27 22:16:56.487 18342 18734 D zjdroid-shell-com.imlk.BlackAndWhite: start disassemble the mCookie -1
```
？？？？
戛然而止？？？


第一时间想到肯定和那个`-1`有关系，反正手头有`ZjDroid`的源码，看看到底是哪里崩了。
字符串搜索，走起！


### 在修复的边缘试探

首先想看看执行`dump_dexinfo`命令的时候，输出的那个`-1`究竟是哪里来的，
到`ZjDroid`的源码里搜索`mCookie:`
（这里有一个小技巧，到`github`的项目首页，顶栏可以指定在这个项目里搜索），

果然搜到一处`com.android.reverse.request.DumpDexInfoCommandHandler`中的`doAction()`方法输出了这个`-1`
```
public class DumpDexInfoCommandHandler implements CommandHandler {

	@Override
	public void doAction() {
		HashMap<String, DexFileInfo> dexfileInfo = DexFileInfoCollecter.getInstance().dumpDexFileInfo();
		Iterator<DexFileInfo> itor = dexfileInfo.values().iterator();
		DexFileInfo info = null;
		Logger.log("The DexFile Infomation ->");
		while (itor.hasNext()) {
			info = itor.next();
			Logger.log("filepath:"+ info.getDexPath()+" mCookie:"+info.getmCookie()); //这里输出啦
		}
		Logger.log("End DexFile Infomation");
	}

}
```

到as里面定位到这个文件，溯源到`com.android.reverse.collecter.DexFileInfoCollecter`的`dumpDexFileInfo()`方法

```
	public HashMap<String, DexFileInfo> dumpDexFileInfo() {
		HashMap<String, DexFileInfo> dexs = new HashMap<String, DexFileInfo>(dynLoadedDexInfo);
		Object dexPathList = RefInvoke.getFieldOjbect("dalvik.system.BaseDexClassLoader", pathClassLoader, "pathList");
		Object[] dexElements = (Object[]) RefInvoke.getFieldOjbect("dalvik.system.DexPathList", dexPathList, "dexElements");
		DexFile dexFile = null;
		for (int i = 0; i < dexElements.length; i++) {
			dexFile = (DexFile) RefInvoke.getFieldOjbect("dalvik.system.DexPathList$Element", dexElements[i], "dexFile");
			String mFileName = (String) RefInvoke.getFieldOjbect("dalvik.system.DexFile", dexFile, "mFileName");
			int mCookie = RefInvoke.getFieldInt("dalvik.system.DexFile", dexFile, "mCookie"); //这里通过反射获取"mCookie"这个int类型的变量
			DexFileInfo dexinfo = new DexFileInfo(mFileName, mCookie, pathClassLoader);
			dexs.put(mFileName, dexinfo);
		}
		return dexs;
	}
```

可以看到：
源码中，通过反射获取"mCookie"这个int类型的变量，然后结果得到的是`-1`，看到这里我也没多想，就想去验证这个变量是否真的是`-1`

想达到这个目的，首先我想到的是用as动态调试一波走起。


### 尝试用动态调试找出-1

结合上面的代码，可以总结出，应该是
BaseDexClassLoader中的
dexElements数组中的元素中的
dexFile中的
mCookie

随便下个断点，方便起见，我经常下的断点就是`OnClickListener`接口中的`onClick`方法，注意给**接口中的方法**下断点的话，所有的实现了这个**接口方法**类的这个方法都能被`debug`捕捉到，

这样不需要修改源程序，就能轻松的下断点，
我们只要点击任意一个可点击的`view`触发了它的`onClick`方法，调试器就能捕捉到，之后我们就能任意查看内容了。

调试器中插入代码，查看内容
![调试器查看内容](/images/blog/40_0.png)


WTF!!!
`mCookie`居然是个`Long[]`，说好的`int`呢！
![查看 mCookie 这个成员变量的类型](/images/blog/40_1.png)

居然是Object！


回去看ZjDroid源码，从`getFieldInt`方法切入
```
			int mCookie = RefInvoke.getFieldInt("dalvik.system.DexFile", dexFile, "mCookie");
```

```
	public static int getFieldInt(String class_name,Object obj, String filedName){
		try {
			Class obj_class = Class.forName(class_name);
			Field field = obj_class.getDeclaredField(filedName);
			field.setAccessible(true);
			return field.getInt(obj);
		} catch (SecurityException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NoSuchFieldException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalArgumentException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return -1; //这里！！！！！！！！！！
		
	}
```

似乎是调用`Field`类型的对象的`getInt()`方法发生了异常（肯定会发生异常啦，这个变量都是个数组，不可能得到`int`类型，异常也是情理之中的），
发生异常以后，只能输出 `-1` 了，


用同样的动态调试方法，对`Android 4.4的模拟器进行测试`：
![调试器查看内容，Android4.4](/images/blog/40_2.png)
![查看 mCookie 这个成员变量的类型](/images/blog/40_3.png)

看来应该是`art`虚拟机和`dalvik`虚拟机的不同造成的，在Android4.4上面这个变量是`int`类型的，


不过我倒是来了兴趣，想试试能不能修复这个问题，不过这就要对`mCookie`深入研究研究了。


### 第二天

起床搜了搜资料，网上也有好多人遇到了这个问题。

不过关于`mCookie`的详细叙述倒是没多少

退回原点，看看崩溃时的异常：

```
    --------- beginning of crash
04-28 10:31:34.468 17165-20179/com.imlk.BlackAndWhite E/AndroidRuntime: FATAL EXCEPTION: Thread-3
    Process: com.imlk.BlackAndWhite, PID: 17165
    java.lang.UnsatisfiedLinkError: dalvik.system.PathClassLoader[DexPathList[[zip file "/data/app/com.android.reverse-1/base.apk"],nativeLibraryDirectories=[/system/lib, /vendor/lib]]] couldn't find "libdvmnative.so"
        at java.lang.Runtime.loadLibrary0(Runtime.java:984)
        at java.lang.System.loadLibrary(System.java:1562)
        at com.android.reverse.util.NativeFunction.<clinit>(NativeFunction.java:19)
        at com.android.reverse.smali.MemoryBackSmali.disassembleDexFile(MemoryBackSmali.java:76)
        at com.android.reverse.collecter.DexFileInfoCollecter.backsmaliDexFile(DexFileInfoCollecter.java:141)
        at com.android.reverse.request.BackSmaliCommandHandler.doAction(BackSmaliCommandHandler.java:19)
        at com.android.reverse.mod.CommandBroadcastReceiver$1.run(CommandBroadcastReceiver.java:33)
        at java.lang.Thread.run(Thread.java:761)
```

说找不到这个`libdvmnative.so`

而这个文件是在ZjDroid项目里的，看看编译出的apk


里面是有这个东西的，真是奇了怪了，xposed框架竟然没帮我把so文件加载进去？？？？？？

后面发现是平台的原因，我的模拟器是x86的，apk里只有arm的源码



### 暂时失败告终

哇，看了一下，这`art`和`dalvik`的区别还是很大的，仅仅是修复这些Java层的代码是行不通的，因为它这里好几个地方用到了so中的`native`方法，这些是不开源的东西，想修改也修改不了。Android7.1.2上的尝试只好放弃了。


不过这里还是学到了一些东西，也第一次尝试了multidex，但是在Android4.4上好像得自己手动加载余下的dex，还真让人头疼啊。


### 船新版本

`github`真的万能啊！！

捞到了`native`部分的源码！

是从一个叫`HeyGirl`的项目里捞到的，这个项目貌似是fork的最早版本的ZjDroid，（不知道是什么原因原项目已不存在），总之从里面捞到了native的源码，可以学习一波啦

又找来了`luajava`的源码，凑在一起基本上就是原版的ZjDroid了。


我为什么要费工夫找这些源码？？？

因为github上面的ZjDroid中只有arm平台的so文件，而我的虚拟机是x86的，没法用，提示找不到so文件。



### 继续尝试脱

输入：
```
adb logcat -s zjdroid-shell-com.imlk.BlackAndWhite
```
logcat：
```
--------- beginning of /dev/log/system
--------- beginning of /dev/log/main
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the package = com.imlk.BlackAndWhite has hook
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the app target id = 3717
```

输入：
```
am broadcast -a com.zjdroid.invoke --ei target 3717 --es cmd '{action:dump_dexinfo}'
```
logcat：
```
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the cmd = dump_dexinfo
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): The DexFile Infomation ->
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): filepath:/data/app/com.imlk.BlackAndWhite-1.apk mCookie:-1204615840
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): End DexFile Infomation
```

输入
```
am broadcast -a com.zjdroid.invoke --ei target 3717 --es cmd '{"action":"backsmali","dexpath":"/data/app/com.imlk.BlackAndWhite-1.apk"}'
```
输出
```
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the cmd = backsmali
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): start disassemble the mCookie -1203426560
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): dvmnative
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): dvmnative
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the dexfile header item info start-->>>>>>>>>>
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the stringStartOffset =112
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the typeStartOffset =2312
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the protoStartOffset =2800
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the fieldStartOffset =4636
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the methodStartOffset =5156
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the classStartOffset =8028
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the classCount =21
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the dexfile header item info end<<<<<<<<<<<--
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): end disassemble the mCookie: cost time = 3s
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): start build the smali files to dex
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): build the dexfile ok
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): end build the smali files to dex: cost time = 0s
D/zjdroid-shell-com.imlk.BlackAndWhite( 3717): the dexfile data save to =/data/data/com.imlk.BlackAndWhite/files/dexfile.dex
```

激动！！！
似乎是成功了，我们去看看在目标路径下有没有我们要的文件：
哇是真的有！！

```
root@generic_x86:/data/data/com.imlk.BlackAndWhite/files # ll
-rw------- u0_a60   u0_a60      12920 2018-04-29 10:44 dexfile.dex
```

快快`adb pull`出来瞧瞧


先用dex2jar处理，然后用jd-gui查看。。。

![脱出来的东西](/images/blog/40_4.png)

我擦这不就是壳子吗？逗我吧！！！


### 继续研究

研究发现

加固应用在加载以后会动态加载两个dex，所以加上apk，一共有三个`DexFile`

可以通过用as调试看出来：

这里的dexElements的来源是：
```
ClassLoader->pathList->dexElements
```

```
dexElements = {DexPathList$Element[3]@831564034400} 
	0 = {DexPathList$Element@831564034360} "dex file "dalvik.system.DexFile@9d139c78""
		dexFile = {DexFile@831563996280} 
			guard = {CloseGuard@831559184936} 
			mFileName = "/data/app/com.imlk.BlackAndWhite-1.apk"
			mCookie = -1192464816
		file = null
		zipFile = null
		zip = null
		isDirectory = false
		initialized = false
	1 = {DexPathList$Element@831564033672} "dex file "dalvik.system.DexFile@9d13a810""
		dexFile = {DexFile@831563999248} 
			guard = {CloseGuard@831559184936} 
			mFileName = "/data/app/com.imlk.BlackAndWhite-1.apk"
			mCookie = -1192527312
		file = null
		zipFile = null
		zip = null
		isDirectory = false
		initialized = false
	2 = {DexPathList$Element@831563727296} "zip file "/data/app/com.imlk.BlackAndWhite-1.apk""
		dexFile = {DexFile@831563726992} 
			guard = {CloseGuard@831559184936} 
			mFileName = "/data/app/com.imlk.BlackAndWhite-1.apk"
			mCookie = -1193659808
		file = {File@831563726728} "/data/app/com.imlk.BlackAndWhite-1.apk"
		zipFile = null
		zip = {File@831563726728} "/data/app/com.imlk.BlackAndWhite-1.apk"
		isDirectory = false
		initialized = false
```



但是原版的`ZjDroid`默认是以文件名称`mFileName`为键`key`，在一个`map`中保存加载了的dex文件的相关信息的，这导致三个文件只被保存了一个信息，于是我魔改了一下，让`ZjDroid`将`mCookie`作为键，发送的命令也通过指定`mCookie`的值来dump我们要的文件，这样就解决了冲突问题。


魔改版本
KB5201314/ZjDroid：
[https://github.com/KB5201314/ZjDroid](https://github.com/KB5201314/ZjDroid)



### 脱！

到这一步可以说是非常nice了。


启动时的输出：
```
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): the package = com.imlk.BlackAndWhite has hook
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): the app target id = 3525
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): openDexFileNative() is invoked with filepath:/data/app/com.imlk.BlackAndWhite-1.apk result:-1196414688
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): openDexFileNative() is invoked with filepath:/data/app/com.imlk.BlackAndWhite-1.apk result:-1196412000
```
那个`result`就是`mCookie`

看一下`dexinfo`
```
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): the cmd = dump_dexinfo
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): The DexFile Infomation ->
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): filepath:/data/app/com.imlk.BlackAndWhite-1.apk dexElementToString:zip file "/data/app/com.imlk.BlackAndWhite-1.apk" mCookie:-1197778512
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): filepath:/data/app/com.imlk.BlackAndWhite-1.apk dexElementToString:dex file "dalvik.system.DexFile@9d19c9d0" mCookie:-1196412000
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): filepath:/data/app/com.imlk.BlackAndWhite-1.apk dexElementToString:dex file "dalvik.system.DexFile@9d19d3c0" mCookie:-1196414688
D/zjdroid-shell-com.imlk.BlackAndWhite( 3525): End DexFile Infomation
```

这就是我魔改的版本啦，可以看到`dexinfo`里还显示了当前文件是dex文件还是zip文件，也给出了`mCookie`

下面对三个文件进行`dumpdex`
```
am broadcast -a com.zjdroid.invoke --ei target 3525 --es cmd '{"action":"dump_dexfile","mCookie":"-1197778512"}'
am broadcast -a com.zjdroid.invoke --ei target 3525 --es cmd '{"action":"dump_dexfile","mCookie":"-1196412000"}'
am broadcast -a com.zjdroid.invoke --ei target 3525 --es cmd '{"action":"dump_dexfile","mCookie":"-1196414688"}'

```

得到的三个文件大小为
```
	 Length Name
	 ------ ----
	 359520 dexdump-1197778512.odex
	  39652 dexdump-1196412000.odex
	1051756 dexdump-1196414688.odex
```

直觉告诉我最大的那个应该是我们要的了


用`backsmali.jar`工具：
```
java -jar E:\toolBox\smali_JesusFreke\baksmali-2.2.2.jar deodex -d .\system\framework\ -o out -a 19 .\dexdump-1196414688.odex
```
- 命令是`deodex`
- 另外，还要指定sdk版本，`-a`参数后面的就是sdk版本，我的模拟器sdk版本是19。
- `-o`是指定输出的文件夹
- 注意这里需要把系统里面的`\system\framework\`文件夹里面的东西手动取出来，因为`backsmali.jar`工具要用到这些东西，`-d`后面的参数就是`framework`文件夹的路径
比如：
我当前文件夹的文件树：
```
.
├── dexdump-1196412000.odex
├── dexdump-1196414688.odex
├── dexdump-1197778512.odex
└── system
    └── framework
        ├── am.jar
        ├── am.odex
        ...
        ├── wm.jar
        └── wm.odex
```


ok，out文件夹下已经是输出的smali文件了，

用`smali.jar`转成dex文件
```
 java -jar E:\toolBox\smali_JesusFreke\smali-2.2.2.jar assemble -a 19 .\out\
```

用jadx开开试试

![jadx查看生成的dex文件](/images/blog/40_5.png)

好激动啊！！！可算是幸苦没有白费


### 改Application

把dex填回原来的apk里面去，再用`apktool`反编译，修改`AndroidManifest.xml`里面的`Application`字段

回编译时出现error，最后一句是

```
W: E:\toolBox\resource\dumped\com.imlk.BlackAndWhite\unsigned\res\layout-v26\abc_screen_toolbar.xml:5: error: No resource identifier found for attribute 'keyboardNavigationCluster' in package 'android'
W:
```

看看`apktool`的`help`
```
usage: apktool b[uild] [options] <app_path>
 -f,--force-all          Skip changes detection and build all files.
 -o,--output <dir>       The name of apk that gets written. Default is dist/name.apk
 -p,--frame-path <dir>   Uses framework files located in <dir>.
```

尝试着用`-p`指定`framework`文件夹：
```
java -jar E:\toolBox\apktool\apktool_2.3.1.jar b -p system\framework unsigned
```

居然成功了！
签名

### 去除`StubApp`

又崩了
```
04-30 02:30:34.604 3999-3999/com.imlk.BlackAndWhite E/AndroidRuntime: FATAL EXCEPTION: main
    Process: com.imlk.BlackAndWhite, PID: 3999
    java.lang.NoClassDefFoundError: com.stub.StubApp
        at com.imlk.BlackAndWhite.MainActivity.<clinit>(Unknown Source)
        at java.lang.Class.newInstanceImpl(Native Method)
        at java.lang.Class.newInstance(Class.java:1208)
...
```

看来有些东西没清理干净

大数字往里面加了静态代码块啊

在jadx里全局搜索`StubApp`，去文件里注释掉

### native的onCreate方法

```
04-30 02:35:41.484 4151-4151/com.imlk.BlackAndWhite E/AndroidRuntime: FATAL EXCEPTION: main
    Process: com.imlk.BlackAndWhite, PID: 4151
    java.lang.UnsatisfiedLinkError: Native method not found: com.imlk.BlackAndWhite.MainActivity.onCreate:(Landroid/os/Bundle;)V
        at com.imlk.BlackAndWhite.MainActivity.onCreate(Native Method)
        at android.app.Activity.performCreate(Activity.java:5231)
        at android.app.Instrumentation.callActivityOnCreate(Instrumentation.java:1087)

```

哇，没想到这个`onCreate`方法居然是`native`的！！！
皮万斤！

看到应用里两个`Activity`里面上一步的静态代码块有一点区别
```
    static {
        StubApp.interface11(0);
    }

```
和
```
    static {
        StubApp.interface11(1);
    }

```

猜测是根据参数值来识别是哪个`Activity`的

看看我们dump出来的其它dex


哇，简直崩溃。。。做不来做不来

### 告一段落

所以说完全复原我是搞不来了，不过仅仅是看看源码还是能的

能力有限啊，搞不了，还是先继续学习吧。。。。


2018_04_30



### 小插曲

编译后安装在`Android4.4`上时偶遇这个问题，
安装上以后，XposedInstaller直接就崩溃了，看日志也一头雾水，上网搜才知道是模块的`versionCode`和`versionName`没有设置，在`gradle.build`里加上就好了。

```
04-29 09:29:04.538 5603-5619/de.robv.android.xposed.installer E/AndroidRuntime: FATAL EXCEPTION: RepositoryReload
    Process: de.robv.android.xposed.installer, PID: 5603
    android.database.sqlite.SQLiteConstraintException: installed_modules.version_name may not be NULL (code 19)
        at android.database.sqlite.SQLiteConnection.nativeExecuteForLastInsertedRowId(Native Method)
        at android.database.sqlite.SQLiteConnection.executeForLastInsertedRowId(SQLiteConnection.java:782)
        at android.database.sqlite.SQLiteSession.executeForLastInsertedRowId(SQLiteSession.java:788)
        at android.database.sqlite.SQLiteStatement.executeInsert(SQLiteStatement.java:86)
        at android.database.sqlite.SQLiteDatabase.insertWithOnConflict(SQLiteDatabase.java:1469)
        at android.database.sqlite.SQLiteDatabase.insertOrThrow(SQLiteDatabase.java:1365)
        at de.robv.android.xposed.installer.repo.RepoDb.insertInstalledModule(RepoDb.java:374)
        at de.robv.android.xposed.installer.util.ModuleUtil.getInstance(ModuleUtil.java:52)
        at de.robv.android.xposed.installer.XposedApp.updateProgressIndicator(XposedApp.java:114)
        at de.robv.android.xposed.installer.util.RepoLoader$2.run(RepoLoader.java:210)
```




### 参考资料

\- Android中Xposed框架篇---基于Xposed的一款脱壳神器ZjDroid工具原理解析：
[https://blog.csdn.net/jiangwei0910410003/article/details/52840602](https://blog.csdn.net/jiangwei0910410003/article/details/52840602)
\- [原创]安卓逆向之基于Xposed-ZjDroid脱壳：
[https://bbs.pediy.com/thread-218798.htm](https://bbs.pediy.com/thread-218798.htm)
\- ZjDroid项目源码（已经停更4年）：
[https://github.com/halfkiss/ZjDroid](https://github.com/halfkiss/ZjDroid)
\- HeyGirl项目地址
[https://github.com/mikusjelly/HeyGirl](https://github.com/mikusjelly/HeyGirl)
\- android am命令用法：
[https://blog.csdn.net/u010164190/article/details/72875865](https://blog.csdn.net/u010164190/article/details/72875865)
\- [原创]360加固逆向脱壳之过反调试：
[https://bbs.pediy.com/thread-213214.htm](https://bbs.pediy.com/thread-213214.htm)
\- [原创]360加固逆向脱壳之过反调试--后续：
[https://bbs.pediy.com/thread-213377.htm](https://bbs.pediy.com/thread-213377.htm)
\- 360加固保动态脱壳：
[https://www.cnblogs.com/2014asm/p/4104456.html](https://www.cnblogs.com/2014asm/p/4104456.html)
\- JesusFreke smali:
[https://bitbucket.org/JesusFreke/smali/downloads/](https://bitbucket.org/JesusFreke/smali/downloads/)

