---
title: 在C++构造函数中转而调用其它构造函数的三种方法
id: 2
aliases:
  - /blog/2/
categories:
  - C/C++
date: 2018-01-19T21:41:51+08:00
tags:
  - 编程语言
  - C++
---


## **C++构造函数中转而调用其它构造函数的三种方法**


**0x00 在初始化列表中调调用另一个构造函数**

```
/**
*	warning: delegating constructors only available with -std=c++11 or -std=gnu++11
*/
```

```
	Teacher::Teacher(): Teacher("unknown",30) {}
```


**0x01 使用this指针显式调用构造函数**

```
/**
*	经过实践发现g++似乎不能这么用
*	error: cannot call constructor ‘Teacher::Teacher’ directly
*	参见：
*	https://stackoverflow.com/questions/9253619/c-cannot-call-constructor-directly
*/	
```

```
	Teacher::Teacher() {
		this->Teacher::Teacher("unknown",30);//此方法必须加上作用域
	}	
```


**0x02 原始内存覆盖**

```
/**
*	使用new (void*p) ClassType(param...)，这种语句的意思是不重新分配内存，而是直接覆盖在原内存上。
*	参见：
*	https://www.jianshu.com/p/4af119c44086
*/
```

```
	Teacher::Teacher():m_iMaxStudentNum(30) {
		new (this) Teacher("unknown",30);
	}
```