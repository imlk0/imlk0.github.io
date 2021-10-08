---
title: CodeForces 699C Vacations——动态规划
id: 6
categories:
  - 算法
date: 2018-02-08 11:49:53
tags:
---

[原题链接](http://codeforces.com/problemset/problem/699/C)


```
C. Vacations
time limit per test
1 second
memory limit per test
256 megabytes
input
standard input
output
standard output

Vasya has n days of vacations! So he decided to improve his IT skills and do sport. Vasya knows the following information about each of this n days: whether that gym opened and whether a contest was carried out in the Internet on that day. For the i-th day there are four options:

    on this day the gym is closed and the contest is not carried out;
    on this day the gym is closed and the contest is carried out;
    on this day the gym is open and the contest is not carried out;
    on this day the gym is open and the contest is carried out. 

On each of days Vasya can either have a rest or write the contest (if it is carried out on this day), or do sport (if the gym is open on this day).

Find the minimum number of days on which Vasya will have a rest (it means, he will not do sport and write the contest at the same time). The only limitation that Vasya has — he does not want to do the same activity on two consecutive days: it means, he will not do sport on two consecutive days, and write the contest on two consecutive days.
Input

The first line contains a positive integer n (1 ≤ n ≤ 100) — the number of days of Vasya's vacations.

The second line contains the sequence of integers a1, a2, ..., an (0 ≤ ai ≤ 3) separated by space, where:

    ai equals 0, if on the i-th day of vacations the gym is closed and the contest is not carried out;
    ai equals 1, if on the i-th day of vacations the gym is closed, but the contest is carried out;
    ai equals 2, if on the i-th day of vacations the gym is open and the contest is not carried out;
    ai equals 3, if on the i-th day of vacations the gym is open and the contest is carried out.

Output

Print the minimum possible number of days on which Vasya will have a rest. Remember that Vasya refuses:

    to do sport on any two consecutive days,
    to write the contest on any two consecutive days. 

Examples
Input

4
1 3 2 0

Output

2

Input

7
1 3 3 2 1 2 3

Output

0

Input

2
2 2

Output

1

Note

In the first test Vasya can write the contest on the day number 1 and do sport on the day number 3\. Thus, he will have a rest for only 2 days.

In the second test Vasya should write contests on days number 1, 3, 5 and 7, in other days do sport. Thus, he will not have a rest for a single day.

In the third test Vasya can do sport either on a day number 1 or number 2\. He can not do sport in two days, because it will be contrary to the his limitation. Thus, he will have a rest for only one day.

```

```
#include <iostream>
#include <cstdio>

using namespace std;

int max(int x, int y) {
	return x > y ? x : y;
}
int max(int x, int y, int z) {
	return x > y ? (x > z ? x : z) : (y > z ? y : z);
}

int main(int argc, char const *argv[])
{
	int t;
	scanf("%d", &t);
	int g_date[t] = {0};//g_date[i](i从0开始)表示第i天体育场是否开放
	int c_date[t] = {0};//c_date[i](i从0开始)表示第i天是否有比赛

	int dp[t][3] = {0};
	// dp[i][x],i从0开始，储存截止到第i天结束工作的天数，工作天数越多，说明休息天数越少
	// [i][0]表示第i天啥都不做，[i][1]表示第i天去体育馆，[i][2]表示第i天打比赛，
	int c_dp[t][2] = {0};

	int temp;

	for (int i = 0; i < t; i++) {
		scanf("%d", &temp);
		switch (temp) {
		case 0:
			break;
		case 1:
			c_date[i] = 1;
			break;
		case 2:
			g_date[i] = 1;
			break;
		case 3:
			c_date[i] = 1;
			g_date[i] = 1;
			break;
		}
	}

	for (int i = 0; i < t ; i++) {
		if (i == 0) {//第一天的情况
			dp[i][0] = 0;

			if (g_date[i]) {//若第i天体育馆开放
				dp[i][1] = 1;//选择去体育馆
			}

			if (c_date[i]) {//若第i天有比赛可打
				dp[i][2] = 1;//选择去打比赛
			}

		} else {//若不是第一天

			dp[i][0] = max(dp[i - 1][1], dp[i - 1][0], dp[i - 1][2]);//选择什么也不做，那么最大工作天数等于昨天的三种情况里最大的那个
			if (g_date[i]) {//若今天体育馆开门
				dp[i][1] = 1 + max(dp[i - 1][0], dp[i - 1][2]);//从昨天啥都不做和昨天去打比赛中选一个最大的
			}//若今天体育馆不开门，显然今天dp[i][1]的状态是不存在的，不能被使用，如何防止以后用到这种不存在的状态呢？这里就和max函数有关系了，只要把不存在的状态的值设置的足够小，那么max函数就肯定不会选取这个比别的数都小的值作为返回值，也就是max函数恰好筛选掉了不合法的状态，而dp[i][1]为默认值0，我们知道工作天数的最小值就是0，所以我们可以大胆地不对dp[i][1]赋值，当然如果你怕出问题的话，你可以赋值为-1或者-inf

			if (c_date[i]) {//若今天有比赛可打
				dp[i][2] = 1 + max(dp[i - 1][1], dp[i - 1][0]);
			}//若今天无比赛，情况和上面的描述类似，可以不赋值(就用默认值0)
		}
	}
	// 最小休息天数 = 总天数 - 最大工作天数
	printf("%d\n", t - max(dp[t - 1][0], dp[t - 1][1], dp[t - 1][2]));
	return 0;
}
```