---
title: CodeForces 891 A. Pride
id: 8
aliases:
  - /blog/8/
categories:
  - Algorithm
date: 2018-02-27T10:30:47+08:00
tags:
  - Codeforces
  - dp
---

[http://codeforces.com/problemset/problem/891/A](http://codeforces.com/problemset/problem/891/A)

```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cmath>

using namespace std;

long long dp[2005][2005]; // dp[x][y]表示gcd(x...(x + y))
/*
x是起始点位置,y是距离
a1, a2, a3, a4, a5, a6, a7, a8
	↑	←	y	→	↑
	x				x + y
*/

// gcd(a1, a2, a3) = gcd(gcd(a1, a2), a3) = gcd(gcd(a1, a2), gcd(a2, a3))
// 所以

// 状态方程
// dp[x][y] = gcd(dp[x][y - 1], dp[x + 1][y - 1])

long long gcd(long long a, long long b) {
	while (1) {
		a = a % b;
		if (!a) {
			return b;
		}
		b = b % a;
		if (!b) {
			return a;
		}
	}
}

int main(int argc, char const *argv[])
{
	int n;
	int ones = 0;
	scanf("%d", &n);

	for (int x = 0; x < n; x++) {
		scanf("%lld", dp[x]);
		if (dp[x][0] == 1) {
			ones++;
		}

		// printf("%lld\t", dp[x][0]);
	}

	// printf("\n");

	if (ones) {
		printf("%d\n", n - ones);
		return 0;
	}

	for (int y = 1; y < n; y++) {//跨度距离从1开始
		for (int x = 0; x + y < n; x++) {//起始位置从x开始

			dp[x][y] = gcd(dp[x][y - 1], dp[x + 1][y - 1]);

			// printf("%lld\t", dp[x][y]);

			if (dp[x][y] == 1) {
				// printf("\n");
				printf("%d\n", n + y - 1);
				return 0;
			}

		}
	}

	printf("-1\n");
	return 0;

/**
*	
*	in:
*	
*	5
*	2 2 3 4 6
*	
*	out:
*	
*	2		2		3		4		6
*	↑↗		↑↗
*	2		1
*	
*	result：
*	
*	5
*	
*	
*/

}

```
