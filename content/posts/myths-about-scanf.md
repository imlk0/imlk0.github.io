---
title: 遇到scanf的一个小误区
id: 26
aliases:
  - /blog/26/
categories:
  - C/C++
date: 2017-12-06T18:43:21+08:00
tags:
  - 编程语言
  - C/C++
---

```
#include <stdio.h>

int main(){

	int a, b;
	while(scanf("%d%d",&a,&b) == EOF){
		printf("%d\n", a + b);	
	}

	return 0;	
}
```

`scanf()` 遇到文件末尾时，如果什么都没有读取到，就返回EOF(-1)，
如果有变量已经赋值那就返回赋值了的变量个数，而不会是EOF。