---
title: 对比学习Java和C++时关于方法覆盖Override后外部调用父类方法的区别
id: 27
aliases:
  - /blog/27/
categories:
  - C/C++
  - Java
date: 2017-11-21T17:30:03+08:00
tags:
  - C++
  - Java
---

以Java语法示范：

![](/images/blog/27_0.png)

面向对象中，B extends A
> // Java中
> 
> 
> B objectB = new B();
> 
> 
> objectB.foo();//输出 from Child Class
> 
> 
> A objectA = new B();
> 
> 
> objectA.foo();//依然输出 from Child Class
> 
> 
> //类型转换不会导致父类方法被调用
> 
> 
> 
> //而，C++中，通过类型转换，可以达到调用父类被覆盖的方法的效果
> 

参考：http://bbs.csdn.net/wap/topics/390171251
