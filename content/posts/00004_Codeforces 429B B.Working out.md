---
title: Codeforces 429B B.Working out
id: 4
categories:
  - 算法
date: 2018-01-09 20:47:19
tags:
---

[http://codeforces.com/problemset/problem/429/B](http://codeforces.com/problemset/problem/429/B)
对于题中刁钻的要求，仔细分析所给条件的等价条件，有时候，所给条件符合的情形只有很少的几种。

[http://blog.csdn.net/cc_again/article/details/25691925](http://blog.csdn.net/cc_again/article/details/25691925)

```
题目意思：
给n*m的矩阵，每个格子有个数，A从(1,1)出发只能向下或右走，终点为(n,m)，B从(n,1)出发只能向上或右走，终点为(1,m)。两个人的速度不一样，走到的格子可以获的该格子的数，两人相遇的格子上的数两个人都不能拿。求A和B能拿到的数的总和的最大值。
n,m<=1000
解题思路：
dp.
先预处理出每个格子到四个角落格子的路径最大数值，然后枚举两个人相遇的交点格子，枚举A、B的进来和出去方式，求最大值即可。
注意边界情况。
```


```
#include <cstdio>
#include <algorithm>

using namespace std;

#define MAX 1005

long data[MAX][MAX];
long dp0[MAX][MAX];
long dp1[MAX][MAX];
long dp2[MAX][MAX];
long dp3[MAX][MAX];

int main() {

	int n, m;

	scanf("%d%d", &n, &m);

	for (int x = 1; x <= n; x++) {

		for (int y = 1; y <= m; y++) {

			scanf("%ld", data[x] + y);
		}
	}

	for (int x = 1; x <= n; x++) {
		for (int y = 1; y <= m; y++) {
			dp0[x][y] = data[x][y] + max(dp0[x - 1][y] , dp0[x][y - 1]);
		}
	}
	for (int x = n; x >= 1; x--) {
		for (int y = m; y >= 1; y--) {
			dp1[x][y] = data[x][y] + max(dp1[x + 1][y] , dp1[x][y + 1]);
		}
	}

	for (int x = n; x >= 1; x--) {
		for (int y = 1; y <= m; y++) {
			dp2[x][y] = data[x][y] + max(dp2[x + 1][y] , dp2[x][y - 1]);
		}
	}
	for (int x = 1; x <= n; x++) {
		for (int y = m; y >= 1; y--) {
			dp3[x][y] = data[x][y] + max(dp3[x - 1][y] , dp3[x][y + 1]);
		}
	}

	long largest = 0;
	for (int x = 2; x < n; x++) {
		for (int y = 2; y < m; y++ ) {

			/**
			* 由于路径只允许重叠一次，根据两人的行动方向可知，重叠时
			* 要么是第一个人从上向下通过，第二个人从左向右通过
			* 要么是第一个人从左向右通过，第二个人从下向上通过
			*/
			largest = max(largest, dp0[x - 1][y] + dp1[x + 1][y] + dp2[x][y - 1] + dp3[x][y + 1]);
			largest = max(largest, dp0[x][y - 1] + dp1[x][y + 1] + dp2[x + 1][y] + dp3[x - 1][y]);

		}
	}

	printf("%ld\n", largest);

	return 0;
}
```