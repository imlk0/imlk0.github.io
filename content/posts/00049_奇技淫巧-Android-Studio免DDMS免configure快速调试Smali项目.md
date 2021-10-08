---
title: '[奇技淫巧]Android Studio免DDMS免configure快速调试Smali项目'
date: 2018-07-19 01:11:30
id: 49
categories:
  - [Android]
  - [Reverse]
tags:
  - [Android Studio]
  - [Debug]
  - [DDMS]
---


### 起因

Android Studio是开发Android应用的一大利器，极大的提高了生产力（虽然比较臃肿），debug功能也非常好用，而且不止能debug Java代码，smali代码也能调试，配合apktool使用真的是爽的很（除了indexing花了老半天这个问题以外）。

但是！这个利器在**调试smali工程的时候**，就表现得十分不友好啦，以前有DDMS的时候还好一些，能看到调试端口号，但是经常遇到DDMS和AndroidStudio的adb端口冲突的问题，水火不容，无奈之下只能`adb shell am start -D -n xxx.xxxx.xxxx/.xxxx`手动以debug模式启动应用，配合`adb forward tcp:xxxx jdwp:xxxx`，但是不知道咋回事经常遇到
```
Unable to open debugger port (localhost:8603): java.io.IOException "handshake failed - connection prematurally closed"
```
每次遇到这种错误，我心中是一万只草泥马飞奔而过啊！这tm还让不让人debug啦！

![WTF!](/images/blog/49_0.png)

### 冷静分析

想起了Android Studio打开纯Android项目的时候，在顶部工具栏会有一个调试用的按钮`Attach debugger to Android process`,就是那个图标是竖着的长方形，右下角一只小虫子的按钮，点一下可以选择要attch的进程
![Attach debugger to Android process](/images/blog/49_1.png)

这个功能在开发的时候用起来很爽，但是当我们打开的不是Android项目时：
![WTF!](/images/blog/49_2.png)

这个按钮没了
![假的Android Studio吧](/images/blog/49_3.png)

### 别着急

这应该是Android Studio 设计的问题，它被设计成了只要不是Android项目就不显示那些按钮，但是它忽略了调试smali的情况

冷静，何必和一个小按钮过意不去呢，让我们来想想对策。

Run -> 没有
Help -> Find Action -> 搜不到

就在这山穷水复无路之际，突然想出个点子：

**快捷键！**
**快捷键！**
**快捷键！**


### 解决办法是快捷键

**Setting -> 搜索 -> Attach debugger to Android process -> keymap**

![真·Attach debugger to Android process](/images/blog/49_4.png)

不出所料真的搜到了，**这里的快捷键是我添加的，原先没有快捷键**，我设置的是`Ctrl + Alt + R`
R就是`reverse`嘛，+D的都被占了没办法。

确认，出来试试。

果然功夫不负有心人！

![真·Choose Process](/images/blog/49_5.png)

测试发现完全ok！

### ~~DDMS，再见~~

去你丫的DDMS，再见（丢）！
![丢了](/images/blog/49_6.png)

不行。。。

![捡起](/images/blog/49_7.png)
Android Studio 里还没有 Method Profiling 呢
