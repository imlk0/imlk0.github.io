---
title: HDU 1711 Number Sequence ——KMP
date: 2018-03-14T16:00:31+08:00
id: 18
aliases:
  - /blog/18/
categories:
  - 算法
tags:
---

[http://acm.hdu.edu.cn/showproblem.php?pid=1711](http://acm.hdu.edu.cn/showproblem.php?pid=1711)

> ##Problem Description
>
> Given two sequences of numbers : a[1], a[2], ...... , a[N], and b[1], b[2], ...... , b[M] (1 <= M <= 10000, 1 <= N <= 1000000). Your task is to find a number K which make a[K] = b[1], a[K + 1] = b[2], ...... , a[K + M - 1] = b[M]. If there are more than one K exist, output the smallest one.
>  
> 
> Input
> The first line of input is a number T which indicate the number of cases. Each case contains three lines. The first line is two numbers N and M (1 <= M <= 10000, 1 <= N <= 1000000). The second line contains N integers which indicate a[1], a[2], ...... , a[N]. The third line contains M integers which indicate b[1], b[2], ...... , b[M]. All integers are in the range of [-1000000, 1000000].
>  
> 
> Output
> For each test case, you should output one line which only contain K described above. If no such K exists, output -1 instead.
>  
> 
> Sample Input
> 
> 2
> 13 5
> 1 2 1 2 3 1 2 3 1 3 2 1 2
> 1 2 3 1 3
> 13 5
> 1 2 1 2 3 1 2 3 1 3 2 1 2
> 1 2 3 2 1
> 
>  
> 
> Sample Output
> 
> 6
> -1

### KMP的使用

从头到尾彻底理解KMP：
[https://www.cnblogs.com/zhangtianq/p/5839909.html](https://www.cnblogs.com/zhangtianq/p/5839909.html)

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>

//AC

//KMP
using namespace std;


int q[1000005];
int sub[10005];
int nextsub[10005];
int t, n, m;


int main(int argc, char const *argv[])
{
	scanf("%d", &t);

	while (t--) {

		scanf("%d%d", &n, &m);

		for (int i = 0; i < n; i++) {
			scanf("%d", q + i);
		}
		for (int i = 0; i < m; i++) {
			scanf("%d", sub + i);
		}

		nextsub[1] = 0;

		for (int i = 1; i < m; i++) {
			int cpi = i;
			while (1) {
				if (cpi == 0) {
					nextsub[i + 1] = 0;
					break;
				}

				if (sub[nextsub[cpi]] == sub[cpi]) {
					nextsub[i + 1] = nextsub[cpi] + 1;
					break;
				} else {
					cpi = nextsub[cpi];
				}
			}
		}

		int i = 0, j = 0, find = 0;
		while (i < n) {
			if (q[i] == sub[j]) {
				i++;
				j++;

				if (j == m) {
					find = 1;
					printf("%d\n", i - m + 1);
					break;
				}
			} else {
				if (j == 0) {
					i++;
				}

				j = nextsub[j];
			}
		}
		if (!find) {
			printf("-1\n");
		}
	}

	return 0;
}

```
