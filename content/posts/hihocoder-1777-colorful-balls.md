---
title: '[hihoCoder]1777 彩球'
date: 2018-07-13T16:28:27+08:00
id: 47
aliases:
  - /blog/47/
categories:
  - Algorithm
tags:
  - hihoCoder
  - 快速幂
  - 快速乘
  - 大数处理
---

### 原题
[https://hihocoder.com/problemset/problem/1777](https://hihocoder.com/problemset/problem/1777)

### 输入

> 第一行三个正整数 n, k, P
  对于50%的数据，有1 ≤ n, k, P ≤ 10^9
  对于100%的数据，有1 ≤ n, k, P ≤ 10^18

### 解法
考察大数的幂次取模
乘法溢出

用快速幂和快速乘解题

```cpp
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

using namespace std;

// 快速乘

long long fastMultiply(long long a, long long b, long long p) {

	long long ans = 0;
	long long t = a;

	while (b) {
		if (b & 1) {
			ans = (ans + t) % p;
		}
		t = (t + t) % p;
		b = b >> 1;
	}

	return ans;
}


// 快速幂
long long fastPow(long long n, long long k, long long p) {
	long long ans = 1;
	long long t = n;
	while (k) {
		if (k & 1) {
			ans = fastMultiply(ans, t, p);
		}
		t = fastMultiply(t, t, p);
		k = k >> 1;
	}
	return ans;
}



int main(int argc, char const *argv[]) {

	long long n, k, p;
	scanf("%lld%lld%lld", &n, &k, &p);

	printf("%lld\n", fastPow(k, n, p));

	return 0;
}
```