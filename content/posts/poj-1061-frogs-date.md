---
title: 'POJ 1061 青蛙的约会'
date: 2018-07-13T16:08:54+08:00
id: 46
aliases:
  - /blog/46/
categories:
  - Algorithm
tags:
  - POJ
  - 扩展欧几里得
---

### 原题
[http://poj.org/problem?id=1061](http://poj.org/problem?id=1061)

### 解法

此题用扩展欧几里得计算
(n-m) * X ≡ (x-y) (mod l) 的最小正整数解
即(n-m) * X + l * Y = (x-y)

贝祖定理： **ax + by = m 有整数解时当且仅当m是gcd(a,b)的倍数。**
用扩展欧几里得能算出**ax + by = gcd(a,b)**的一个特解
此特解乘上**m / gcd(a,b)**得到的就是**ax + by = m**的特解

**所有的解x mod (b/gcd(a,b))同余**
**所有的解y mod (a/gcd(a,b))同余**


### 参考

[https://blog.csdn.net/ccnuacmhdu/article/details/79415284](https://blog.csdn.net/ccnuacmhdu/article/details/79415284)
[https://www.cnblogs.com/xeoncdy/p/7265419.html](https://www.cnblogs.com/xeoncdy/p/7265419.html)
[https://blog.csdn.net/sun897949163/article/details/51894372](https://blog.csdn.net/sun897949163/article/details/51894372)
[https://blog.csdn.net/yoer77/article/details/69568676](https://blog.csdn.net/yoer77/article/details/69568676)



```cpp
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

#define LL long long
using namespace std;

LL x, y, m, n, l;


// 扩展欧几里得求二元一次方程的一个解
LL exGCD(LL a, LL b, LL&x, LL&y) {
	if (b == 0) {
		x = 1;// a * 1 + b * 0 = a
		y = 0;
		return a;
	}

	LL r = exGCD(b, a % b, x, y);

	LL t_y = y;
	y = x + (-a / b) * y;
	x = t_y;

	return r;//返回值为gcd
	// 记法：该函数返回时满足 a * x + b * y = gcd; 调整x和y只是为了返回上一层调用后能重新调整x'和y'
	// x' = y
	// y' = x + (-a/b) * y
}


int main(int argc, char const *argv[]) {

	scanf("%lld%lld%lld%lld%lld", &x, &y, &m, &n, &l);


	LL a = ((n - m) % l + l ) % l;//（将X的系数化为正的）

	LL x0, y0;

	LL gcd = exGCD(a, l, x0, y0);

	if ((!a) || (x - y) % gcd) {
		printf("Impossible\n");
		return 0;
	}

	x0 = x0 * (x - y) / gcd;// x0原先是 (n-m) * X + l * Y = gcd 的一个特解，现在将它化为 (n-m) * X + l * Y = (x-y)的特解X0

	// 找出最小的正整数解X0,所有X mod (b/gcd(a,b))同余
	x0 = ((x0 % (l / gcd)) + (l / gcd)) % (l / gcd);// 用%表示mod的办法
	printf("%lld\n", x0);


	return 0;
}
```
