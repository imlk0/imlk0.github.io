---
title: '[POJ]1150 The Last Non-zero Digit'
date: 2018-07-13 16:02:29
id: 45
categories: 
  - [POJ]
  - [算法]
tags:
  - [POJ]
  - [阶乘]
  - [最低非零位]
---

### 原题
[http://poj.org/problem?id=1150](http://poj.org/problem?id=1150)

### 参考
[https://blog.csdn.net/txl199106/article/details/40653579](https://blog.csdn.net/txl199106/article/details/40653579)


```cpp
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

#define LL long long

using namespace std;



// 除了统计2，5的总因子数，还统计末尾位为3，7，9的数目

void count(LL co[], int n) {
	if (n == 0) {
		return;
	}

	for (int m = n; m > 0; m = m / 5) {// 处理1...n之间的奇数的末尾位
		// 末尾位可能为1, 3, 5, 7, 9
		// 1无需统计，3,7,9只要求统计出现在末位的次数
		// 5需要统计作为因子出现过的次数

		// 将这些奇数分为以5的倍数和非5的倍数
		// 例如1,3,5,7,9,11,13...,53,55,57,59
		// 分为1,3,7,9,11,13,17...,53,57,59和5*1，5*3，5*5...5*11，在for循环里每次m处以5来实现问题转换


		// 先统计1...m的奇数中不含因子5的数中末尾3，7，9出现的次数
		co[1] += m / 10 + ((m % 10) >= 3); // m[1] 统计3
		co[3] += m / 10 + ((m % 10) >= 7); // m[1] 统计7
		co[4] += m / 10 + ((m % 10) >= 9); // m[1] 统计9


		// 开始问题转换（利用for循环）(其实也可像下面那样用递归)
		// 将1...m的奇数中含有因子5的（5，15，25，35...）(共有(m / 10 + ((m % 10) >= 5))个)，先处以因子5，转化为统计（1，3，5，7...）
		co[2] += m / 10 + ((m % 10) >= 5);//统计因子5
	}

	// m[0] 统计2
	co[0] += n / 2;// 处理1...n之间的偶数，每个先处以2，问题转换为统计1...(n/2)，采用递归
	count(co, n / 2);
}

int main(int argc, char const *argv[]) {
	int n, m;

	while (~scanf("%d%d", &n, &m)) {


		if (m == 0) {
			printf("1\n");
			continue;
		}

		LL co_1[5] = {0};//依次统计2，3，5，7，9的数目
		LL co_2[5] = {0};

		count(co_1, n);// 统计1...n
		count(co_2, n - m);// 统计1...n-m
		// 统计完相减
		// for (int i = 0; i < 5; ++i)
		// {
		// 	printf("%d ", co_1[i]);
		// }
		// printf("\n");
		// for (int i = 0; i < 5; ++i)
		// {
		// 	printf("%d ", co_2[i]);
		// }
		// printf("\n");

		int ans = 1;

		int r_2[] = {6, 2, 4, 8}; // 观察发现，2^i的尾数循环出现（除了2^0尾数是1外，其余情况尾数都以6，2, 4, 8...出现）（例如 1，2，4，8，16，32，64）
		int r_3[] = {1, 3, 9, 7}; // 3^i的尾数循环出现
		int r_7[] = {1, 7, 9, 3}; // 7^i的尾数循环出现
		int r_9[] = {1, 9}; // 9^i的尾数循环出现


		ans = (ans * r_3[(co_1[1] - co_2[1]) % 4]) % 10;
		ans = (ans * r_7[(co_1[3] - co_2[3]) % 4]) % 10;
		ans = (ans * r_9[(co_1[4] - co_2[4]) % 2]) % 10;

		if (co_1[0] - co_2[0] > co_1[2] - co_2[2]) {
			// 2的数目多于5
			ans = (ans * r_2[((co_1[0] - co_2[0]) - (co_1[2] - co_2[2])) % 4]) % 10;
		} else if (co_1[0] - co_2[0] < co_1[2] - co_2[2]) {
			// 5的数目多于2
			ans = 5;// 奇数乘以5，尾数依然是5
		}// 2的数目和5的数目相同时乘1，无需乘


		printf("%d\n", ans);


	}

	return 0;
}
```
