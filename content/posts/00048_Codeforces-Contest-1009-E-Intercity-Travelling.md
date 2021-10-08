---
title: '[Codeforces]Contest 1009 E. Intercity Travelling'
date: 2018-07-15 21:06:24
id: 48
categories:
  - [算法]
  - [Codeforces]
tags:
  - [Codeforces contest 1009]
  - [Educational Codeforces Round 47 (Rated for Div. 2)]
  - [Codeforces]
---

### 链接
Educational Codeforces Round 47 (Rated for Div. 2) - E. Intercity Travelling
[http://codeforces.com/contest/1009/problem/E](http://codeforces.com/contest/1009/problem/E)


### 思路

n千米，有n段路，共有n-1个可能可以休息的地方，则共有2^(n-1)种可能的休息方式;
要计算 p⋅2^(n−1)，也就是计算所有的可能的休息方式下的消耗之和;
分解出来，就是要计算所有的可能的休息方式中所有的a[i]的和;
也就是求和 sum(a[i] * 消耗a[i]出现的总次数) (i->1,2,3,...n);

我们可以按照这种思路，统计a[1]出现的总次数，a[2]出现的次数，这个应该是有规律的;
```
例如n=4的情况

0  1  2  3  4
#--#--#--#--#
其中 1,2,3 这几个点既可以是休息，也可以是不休息两种状态
```

先考虑简单的，要使a[1]出现:
```
若a[1]出现在 0-1 之间，显然这是必定的，和 1,2,3 休息与不休息都没关系，有所以在 0-1 出现a[1]的次数是 2^3 = 2^(n-1) 次
若a[1]出现在 1-2 之间，则必须是在 1 点处休息了，而 2，3 处则没关系，那么所有在 1-2 出现a[1]的次数是 2^2 = 2^0 * 2^(n-2) = 2^(n-2) 次
若a[1]出现在 2-3 之间，则必须是在 2 点休息了，和在 1，3 的状况没关系，那么所有在 2-3 出现a[1]的次数是 2^2 = 2^1 * 2^(n-3) = 2^(n-2) 次
同理可得a[1]出现在 3-4 之间的次数是 2^2 = 2^2 * 2^(n-4) = 2^(n-2) 次

则a[1]出现的总次数是 2^3 + 2^2 + 2^2 + 2^2
```
再考虑a[2],a[3],a[4]的情况，
a[2]出现的总次数是 2^2 + 2^1 + 2^1
a[3]出现的总次数是 2^1 + 2^0
a[4]出现的总次数是 2^0


可以发现规律
**a[i]出现的次数是 2^(n-i) + 2^(n-i-1) * (n-i)**

乘以a[i]加起来就是答案


拙劣代码：
```cpp
#include<iostream>
#include<cstdio>
#include<cstring>
#include<algorithm>

#define MOD 998244353

using namespace std;

// n最大为100000, n^2算法不可取

int n;
// long long an[1000005];
long long _2n[1000005];


int main(int argc, char const *argv[]) {

	scanf("%d", &n);

	_2n[0] = 1;


	int b = 1;
	for (int i = 1; i < n; ++i) {
		b = (b * 2) % MOD;
		_2n[i] = b;
	}


	long long a;
	long long ans = 0;
	for (int i = 1; i <= n; ++i) {
		scanf("%lld", &a);
		ans = (ans + ((_2n[n - i] + ((n - i) * _2n[n - i - 1]) % MOD) * a) % MOD) % MOD;
	}

	printf("%lld\n", ans);


	// TL旧代码

	// for (int k = 1; k <= n; ++k) {
	// 	ans = (ans + ans) % MOD;
	// 	printf("x2\n");
	// 	for (int i = 1; i < k; ++i) {
	// 		ans = (ans + an[i] * _2n[k - i - 1]) % MOD;
	// 		printf("+a[%d] x 2^%d\n", i, k - i - 1);
	// 	}
	// 	ans = (ans + an[k]) % MOD;
	// 	printf("+a[%d] x 2^0\n", k);
	// }


	return 0;
}
```
