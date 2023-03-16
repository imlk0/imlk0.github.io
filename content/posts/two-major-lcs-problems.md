---
title: 两大LCS问题
id: 25
aliases:
  - /blog/25/
categories:
  - Algorithm
date: 2018-02-01T12:09:09+08:00
tags:
  - LCS
---

## 0x00 相同子序：（不要求连续）

```
#include <iostream>
#include <algorithm>
#include <string>
#include <cstdio>

// // #define DEBUG
// #ifdef DEBUG
// #define SHOW
// #else
// #define SHOW /##/
// #endif
// 不可行，注释先于预处理指令被处理

using namespace std;

// LCS共同子序不要求连续

int main(int argc, char const *argv[])
{
	string s1, s2;
	while (cin >> s1 >> s2) {
		int len1 = s1.length();//不包括末尾的'\0'
		int len2 = s2.length();
		int ans = 0;
		int dp[len1 + 5][len2 + 5] = {};//初始化为0避免边界讨论

		// printf("\t\t");
		// for (int y = 0; y < len2; y++) {
		// 	printf("%c\t", s2[y]);
		// }
		// printf("\n\t");

		// for (int y = 0; y <= len2; y++) {
		// 	printf("%d\t", dp[0][y]);

		// }
		// printf("\n");

		for (int x = 1; x <= len1; x++) {
			// printf("%c\t", s1[x - 1]);
			// printf("%d\t", dp[x][0]);
			for (int y = 1; y <= len2; y++) {
				if (s1[x - 1] == s2[y - 1]) {//之所以减一是由于循环变量从1开始
					dp[x][y] = dp[x - 1][y - 1] + 1;// 等于左上方格子加一
					// printf("↖%d\t", dp[x][y]);
				} else {
					dp[x][y] = max(dp[x - 1][y], dp[x][y - 1]);// 向左上方的所有格子取最大值(实际上只需要从左边和上边选取最大值)
					// if (dp[x][y] == dp[x - 1][y]) {
					// 	printf("↑%d\t", dp[x][y]);
					// } else {
					// 	printf("←%d\t", dp[x][y]);
				}
			}

			// printf("\n");
		}

		/**
		*	abcfbc abfcab
		*	dp数组:
		*
		*			a	b	f	c	a	b
		*		0	0	0	0	0	0	0
		*	a	0	↖1	←1	←1	←1	↖1	←1
		*	b	0	↑1	↖2	←2	←2	←2	↖2
		*	c	0	↑1	↑2	↑2	↖3	←3	←3
		*	f	0	↑1	↑2	↖3	↑3	↑3	↑3
		*	b	0	↑1	↖2	↑3	↑3	↑3	↖4
		*	c	0	↑1	↑2	↑3	↖4	←4	↑4
		*	
		*	out:4
		*/

		for (int x = 1; x <= len1; x++) {
			for (int y = 1; y <= len2; y++) {
				ans = max(ans, dp[x][y]);
			}
		}
		printf("%d\n", ans);

	}
	return 0;
}
```

## 0x01 相同子列（连续）

```

#include <iostream>
#include <algorithm>
#include <string>
#include <cstdio>

using namespace std;

// LCS共同连续子列

int main(int argc, char const *argv[])
{
	string s1, s2;
	while (cin >> s1 >> s2) {
		int len1 = s1.length();//不包括末尾的'\0'
		int len2 = s2.length();
		int ans = 0;
		int dp[len1 + 5][len2 + 5] = {};//初始化为0避免边界讨论

		// printf("\t\t");
		// for (int y = 0; y < len2; y++) {
		// 	printf("%c\t", s2[y]);
		// }
		// printf("\n\t");

		// for (int y = 0; y <= len2; y++) {
		// 	printf("%d\t", dp[0][y]);

		// }
		// printf("\n");

		for (int x = 1; x <= len1; x++) {
			// printf("%c\t", s1[x - 1]);
			// printf("%d\t", dp[x][0]);
			for (int y = 1; y <= len2; y++) {
				if (s1[x - 1] == s2[y - 1]) {//之所以减一是由于循环变量从1开始
					dp[x][y] = dp[x - 1][y - 1] + 1;// 等于左上方格子加一
					// printf("↖%d\t", dp[x][y]);
				}//不相等则无需处理
				// else {
				// 	printf("%d\t", dp[x][y]);
				// }
			}

			// printf("\n");
		}

		/**
		*	abcfbc abfcab
		*	dp数组:
		*
		*			a	b	f	c	a	b
		*		0	0	0	0	0	0	0
		*	a	0	↖1	0	0	0	↖1	0
		*	b	0	0	↖2	0	0	0	↖2
		*	c	0	0	0	0	↖1	0	0
		*	f	0	0	0	↖1	0	0	0
		*	b	0	0	↖1	0	0	0	↖1
		*	c	0	0	0	0	↖1	0	0
		*
		*	out:2
		*/

		for (int x = 1; x <= len1; x++) {
			for (int y = 1; y <= len2; y++) {
				ans = max(ans, dp[x][y]);
			}
		}
		printf("%d\n", ans);

	}
	return 0;
}

```