---
title: codeforces contest 1082 E. Increasing Frequency
date: 2018-11-30 00:06:03
id: 50
categories: 
  - [Codeforces]
  - [算法]
tags: 
  - [Codeforces]
  - [贪心]
  - [dp]
---

[原题在这](http://codeforces.com/contest/1082/problem/E)

这题搞了好久，大意是讲给一个长为n的数串，让其中**某一个子区间的数**都+k，然后使得整个串里等于c的数个数尽可能大，问最大多少

串里的数范围挺宽的，先想这个+k，实际上就是尽可能多的把不是c的变成c，尽量少把c变成其它的，要注意这里k选定了以后，能变成c的数就只有是c-k

由于串里的c一开始的数量是确定的，于是最终c的数量=原来c的数量+(变成了c的数的数量-变成了别的数的c的数量)，其实我们就是要求括号里的最大值


### dp

代码是我看了别人的提交后写的，感觉这里能想到dp的都是神仙吧，(这都什么人呀!!!!)

理解了这个dp后我才修好了我下面写的贪心

```cpp
#include<cstdio>
#include<cmath>
#include<cstring>
#include<algorithm>
#include<iostream>

using namespace std;

#define MAXN 500005

int n, c;

// 答案 = c的次数(不变)+最佳的(区间内非c的某种元素出现次数-c的出现次数)

int cl[MAXN];
int pre[MAXN];// 保存遍历过程中i上一次出现的位置
int dp[MAXN];// dp[i]以i位置结尾处的最佳结果
int dpo[MAXN];// 以c-i作为k的最佳结果

int main(int argc, char const *argv[]) {

	scanf("%d%d", &n, &c);

	int t;

	int result = 0;

	for (int i = 1; i <= n; ++i) {
		scanf("%d", &t);

		if (t == c) {
			cl[i]++;
		}
		cl[i] += cl[i - 1];// 前缀数组


		if (t == c) {
			dp[i] = max(0, dp[i - 1] - 1);// 要么c所在位置不选，则以此处为结尾的最佳差值为0；要么选上,则继承以上一个位置结尾的差值再减去1
		} else {// 不为c时
			dpo[i] = max(1, (dpo[pre[t]] + 1) - (cl[i] - cl[pre[t]])); // 从上次这个t出现的位置（不包括）到这个位置结束这段区间，要么从当前位置重新开始一个区间(1)（肯定比不开始(0)好），要么接上上一段区间，其它情况都不如这两种情况；
			dp[i] = max(dp[i - 1], dpo[i]);//要么不是当前的t为参照进行变换(dp[i-1])，要么是(dpo[i])
		}

		pre[t] = i;

		result = max(result, dp[i]);
	}

	result += cl[n];//最后得加上总序列中c出现的次数

	printf("%d\n", result);

	return 0;
}
```


### 贪心

这题一开始考虑数据范围很大，二层三层循环啥的肯定gg，然后想到**求一段给定数列的子区间和的最大值的方法**，那种方法只要一次遍历数组不断更新前缀和的最小值，然后每次更新max(当前的前缀和-之前找到的最小值)

这里也效仿一下，对所有除了c以外出现的数都这么求
注意这里计算最小前缀和的时刻我放到了遇到t并处理之前，然后再计算当前前缀和，然后再相减更新结果


注意在这里k是有很多取值的（因为串里的数在一个情况下都能变成c），我们这里一并进行运算了，这些k的取值情况之间相互是没有联系的，具体的看代码吧

```cpp
#include<cstdio>
#include<cmath>
#include<cstring>
#include<algorithm>
#include<iostream>

using namespace std;

//用了类似于一次遍历数组求区间最大和的那种办法的思想（即遍历数组不断max(当前前缀和-min(历史上的前缀和))），对除了c以外的那些数都做这种计算


#define MAXN 500005

int n, c;

int cl[MAXN];//c的出现次数前缀数组

int mins[MAXN];//历史上(i出现次数-那时c出现次数取最小值的时候)i出现次数的值
int minpos[MAXN];//i出现上述最小值的位置
int nows[MAXN];//当前出现i的次数

int main(int argc, char const *argv[]) {

	scanf("%d%d", &n, &c);

	int result = 0;

	int t;

	for (int i = 1; i <= n; ++i) {
		scanf("%d", &t);

		cl[i] += cl[i - 1];

		if (t == c) {
			cl[i]++;
		} else {

			//每次在遇到t时,先计算一下在这次t出现之前的最小前缀和，不考虑除t和c以外的其它元素，因为此时k=c-t已经确定，其它数在这种情况下没有影响
			if (nows[t] - cl[i] < mins[t] - cl[minpos[t]]) {
				mins[t] = nows[t];
				minpos[t] = i - 1;
			}

			//然后再考虑这次t的出现，处理t
			nows[t]++;

			//相减更新结果
			result = max(result, ((nows[t] - cl[i]) - (mins[t] - cl[minpos[t]])));

		}
	}

	result += cl[n];

	printf("%d\n", result);
	return 0;
}
```




