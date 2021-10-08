---
title: Fragment != Fragment ? —— Xposed开发时遇到的关于ClassLoader的问题
id: 10
categories:
  - Xposed
date: 2018-02-25 18:02:56
tags:
---

今天在写Xposed模块的过程中，为了找到某个Field，需要判断Filed的某个祖先的类型是是Fragment类型

但在做比较的时候出现了问题，发生了Fragment != Fragment的问题：

注：这里的 Fragment 是 android.support.v4.app.Fragment 而不是 android.app.Fragment

我们知道v4包是要额外导入的，
![](/images/blog/10_1.png)

所以说，一共出现了两份v4包，一份打包在宿主app里，一份打包在自己的模块里面，在加载的时候会出现因为ClassLoader不一致而导致两个class不同的情况

如图：
![](/images/blog/10_0.png)

**在debug添加查看发现，两个Class虽然都是android.support.v4.app.Fragment但由于ClassLoader不一样，导致两个Class不相等；**

查看其它的Class发现，系统自带的那些jar里面的Class都是由BootClassLoader加载的，
![](/images/blog/10_2.png)
而BootClassLoader的实例在虚拟机中只有一个，所以模块中的Context.class和宿主app里的Context.class是一样的