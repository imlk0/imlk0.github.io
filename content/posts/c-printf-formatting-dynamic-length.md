---
title: printf格式化输出浮点数动态指定长度
id: 9
aliases:
  - /blog/9/
categories:
  - C/C++
date: 2017-12-16T23:55:10+08:00
tags:
  - 编程语言
  - C
---

printf要格式化输出动态长度的数，有两种方法：

**0x00 构造一个字符数组，先根据要动态的长度构造出对应的格式化字符串，然后传入printf的第一个参数。**

**0x01 采用`*`来占用长度的位置**

例如：
```
printf("%.*f", length, num);
```
长度作为第二个参数传入。
