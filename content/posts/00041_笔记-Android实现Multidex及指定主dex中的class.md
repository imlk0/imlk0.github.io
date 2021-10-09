---
title: '[笔记]Android实现Multidex及指定主dex中的class'
date: 2018-04-29T11:19:47+08:00
id: 41
categories:
  - 笔记
tags:
  - 杂文
  - 笔记
---


### 起因

在编译ZjDroid源码的时候遇到了著名的方法数超出`65536`个的问题。

我的`gradle`版本

```
        classpath 'com.android.tools.build:gradle:3.1.2'
```

### 要解决的问题

1. `Xposed`模块中的方法数超过了`65536`个，需要进行分包操作
2. 分包以后如何在模块被加载执行前尽可能早的把其余的dex加载进来
3. 最后遇到的问题：把模块的入口类指定到第一个dex中


### 问题1

关于分包操作：


搜了半天，搜到的解决办法是：
`gradle.build`中在`defaultConfig`中添加
```
        multiDexEnabled true
```
让编译脚本开启分包


### 问题2

关于分包后的加载问题：

网上对于一般应用的解决办法是

引入
```
    implementation 'com.android.support:multidex:1.0.3'
```

在`Application`中调用
```
        MultiDex.install(this);
```
来实现分包应用的启动。

**但是有一个问题是这个`Multidex`的`install`方法需要传入一个`Context`实例，而`Xposed`模块的启动是没有`Application`的，怎么办呢，如果要截获宿主的`Application`又比较麻烦，能不能直接一句话完成呢？**


于是我决定去研究研究`MultiDex`的源码，尝试魔改出一个适用于`Xposed`模块的`MultiDex.install()`。

### 魔改之旅

研究了一番发现，传入的`Context`的主要用途有：

1. 传入`getApplicationInfo`方法获取`ApplicationInfo`
2. 获取应用的私有储存空间路径并往里面解压`dex`文件
3. 获取`SharedPreferences`储存一些和`dex`文件数量以及文件校验相关的信息（考虑的还挺周到）


我发现在模块的

```
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {

```
这个入口函数的参数`lpparam`中，能获取到宿主的`ApplicationInfo`，从而获取到宿主应用的私有文件夹路径

这样我就能往里面解压文件啦

至于文件校验，这个就不做了，（原方案是一次启动的时候解压，然后以后启动的时候就去校验这个文件，再加载进来），我就干脆每次启动的时候都要解压，加载完再删掉就ok了。



### 魔改完成


项目地址：
[https://github.com/KB5201314/XposedModuleMultidex](https://github.com/KB5201314/XposedModuleMultidex)


添加依赖
```
  compile 'top.imlk.xpmodulemultidex:XposedModuleMultidex:1.0.0'
```


删了一大堆，总算是魔改出来了一个，虽然只有两个文件。。。。但还是值得庆幸的！

获取`module`的安装包路径：

通过给入口类继承`IXposedHookZygoteInit`并实现`initZygote`方法
```
    @Override
    public void initZygote(StartupParam startupParam) throws Throwable {
        MODULE_PATH = startupParam.modulePath;
    }
```
就能拿到模块的安装包路径啦。

然后在`handleLoadPackage`中执行
```
...
    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {
        XMMultiDex.install(ReverseXposedModule.class.getClassLoader(),MODULE_PATH,lpparam.appInfo);
...
```
其中`ReverseXposedModule`就是我这个模块的入口类的名称啦。




### 问题3

**指定主`dex`中的`class`文件的问题**

这可废了我不少时间啊，网上的方法大多都过时了，唯一一个看着靠谱的插件`DexKnifePlugin`也用不了，搜了半天，终于找到一位仁兄的方法

在`gradle.build`的`defaultConfig`中可以指定一个文件来表示要放在第一个`dex`中的`class`

加入
```
 multiDexKeepFile file('maindexlist.txt')
```

然后在`gradle.build`的同级目录下新建一个文件`maindexlist.txt`

里面填上要放在第一个`dex`中的`class`

如：
```
com/android/reverse/mod/ReverseXposedModule.class
top/imlk/xpmodulemultidexer/XMMultiDex.class
```


也可以用
```
 multiDexKeepProguard file('maindexlist.pro')
```
然后
新建`maindexlist.pro`文件，这样就可以用`proguard`语法来写

```
-keep class com.android.reverse.mod.ReverseXposedModule
-keep class top.imlk.xpmodulemultidexer.*
```



可算是ok了



### 参考资料

gradle3.0.0分包把指定的class放到maindex里面:
[https://blog.csdn.net/qq_17265737/article/details/79074494](https://blog.csdn.net/qq_17265737/article/details/79074494)
理解 Multidex 生成：
[http://www.jkeabc.com/566905.html](http://www.jkeabc.com/566905.html)
