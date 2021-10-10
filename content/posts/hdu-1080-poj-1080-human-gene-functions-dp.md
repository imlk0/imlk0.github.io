---
title: HDU 1080 POJ 1080 Human Gene Functions——动态规划
id: 12
aliases:
  - /blog/12/
categories:
  - Algorithm
date: 2018-02-26T21:53:24+08:00
tags:
  - POJ
---

[http://poj.org/problem?id=1080](http://poj.org/problem?id=1080)
[http://acm.hdu.edu.cn/showproblem.php?pid=1080](http://acm.hdu.edu.cn/showproblem.php?pid=1080)

```
#include <iostream>
#include <cstdio>
#include <map>
#include <cstring>

#define MAX(x,y,z) ((x)>(y)?((x)>(z)?(x):(z)):((y)>(z)?(y):(z)))

using namespace std;

char str1[105];
char str2[105];
int list[6][6] = {
//	  		{ \0,  A,  C,  G,  T,  -}
	/*\0*/	{  0,  0,  0,  0,  0,  0},
	/*A*/	{  0,  5, -1, -2, -1, -3},
	/*C*/	{  0, -1,  5, -3, -2, -4},
	/*G*/	{  0, -2, -3,  5, -2, -2},
	/*T*/	{  0, -1, -2, -2,  5, -1},
	/*-*/	{  0, -3, -4, -2, -1,  0},
};
map<char, int>m;

int dp[105][105];//dp[x][y]表示str1中1...x-1个字符和str2中第1...y-1之间匹配的最优解

int main(int argc, char const *argv[])
{
	int T, len1, len2;
	scanf("%d", &T);

	m['\0'] = 0;
	m['A'] = 1;
	m['C'] = 2;
	m['G'] = 3;
	m['T'] = 4;
	m['-'] = 5;

	while (T--) {
		memset(dp, 0, sizeof(dp));
		scanf("%d%s", &len1, str1 + 1);
		scanf("%d%s", &len2, str2 + 1);

		// printf("\t\t");
		// for (int y = 0; y < len2; y++) {
		// 	printf("%c\t", s2[y]);
		// }
		// printf("\n\t");

		// for (int y = 0; y <= len2; y++) {
		// 	printf("%d\t", dp[0][y]);

		// }
		// printf("\n");

		for (int x = 1; x <= len1 + 1; x++) {
			dp[x][0] = -1e9;
		}

		for (int y = 1; y <= len2 + 1; y++) {
			dp[0][y] = -1e9;
		}

		for (int x = 1; x <= len1 + 1; x++) {

			for (int y = 1; y <= len2 + 1; y++) {
				dp[x][y] = MAX(
				               dp[x - 1][y - 1] + list[m[str1[x - 1]]][m[str2[y - 1]]],
				               dp[x - 1][y] + list[m[str1[x - 1]]][m['-']],
				               dp[x][y - 1] + list[m['-']][m[str2[y - 1]]]
				           );

//取消注釋打印流程

/*				if (dp[x - 1][y - 1] + list[m[str1[x - 1]]][m[str2[y - 1]]]
				        >= dp[x - 1][y] + list[m[str1[x - 1]]][m['-']]) {
					if (dp[x - 1][y - 1] + list[m[str1[x - 1]]][m[str2[y - 1]]]
					        >=
					        dp[x][y - 1] + list[m['-']][m[str2[y - 1]]]) {
						printf("↖%d\t", dp[x][y]);
					} else {
						printf("←%d\t", dp[x][y]);
					}
				} else {
					if (dp[x - 1][y] + list[m[str1[x - 1]]][m['-']]
					        >=
					        dp[x][y - 1] + list[m['-']][m[str2[y - 1]]]) {
						printf("↑%d\t", dp[x][y]);
					} else {
						printf("←%d\t", dp[x][y]);

					}
				}
*/

			}

/*
			printf("\n");
*/

		}
		printf("%d\n", dp[len1 + 1][len2 + 1]);

		/**
		*
		*	in:
		*	
		*	2
		*	7 AGTGATG
		*	5 GTTAG
		*	7 AGCTATT
		*	9 AGCTTTAAA
		*	
		*	out:
		*	
		*	↖0		←-2		←-3		←-4		←-7		←-9
		*	↑-3		↖-2		↖-3		↖-4		↖1		←-1
		*	↑-5		↖2		←1		←0		↑-1		↖6
		*	↑-6		↑1		↖7		↖6		←3		↑5
		*	↑-8		↖-1		↑5		↖5		↖4		↖8
		*	↑-11	↑-4		↑2		↖4		↖10		←8
		*	↑-12	↑-5		↖1		↖7		↑9		↖8
		*	↑-14	↖-7		↑-1		↑5		↑7		↖14
		*	
		*	14
		*	
		*	↖0		←-3		←-5		←-9		←-10	←-11	←-12	←-15	←-18	←-21
		*	↑-3		↖5		←3		←-1		←-2		←-3		←-4		↖-7		↖-10	↖-13
		*	↑-5		↑3		↖10		←6		←5		←4		←3		←0		←-3		←-6
		*	↑-9		↑-1		↑6		↖15		←14		←13		←12		←9		←6		←3
		*	↑-10	↑-2		↑5		↑14		↖20		↖19		↖18		←15		←12		←9
		*	↑-13	↖-5		↑2		↑11		↑17		↖19		↖18		↖23		↖20		↖17
		*	↑-14	↑-6		↑1		↑10		↖16		↖22		↖24		↑22		↖22		↖19
		*	↑-15	↑-7		↑0		↑9		↖15		↖21		↖27		←24		↖21		↖21
		*	
		*	
		*	21
		*	
		*	
		*	
		*/

	}
	return 0;
}

```

后来发现是自己想得太多了，这个题的“状态”不一定非要理解成原先那样，
其实完全可以也像最大公共子列那样的，
dp[x][y]表示str1的前x个字符和str2的前y个字符之间的匹配结果的最优解
这样也便于理解，便于思考

这样的话dp[x][y]就是最终答案，不过要注意边界的预处理
代码如下

```
#include <iostream>
#include <cstdio>
#include <map>
#include <cstring>

#define MAX(x,y,z) ((x)>(y)?((x)>(z)?(x):(z)):((y)>(z)?(y):(z)))

using namespace std;

char str1[105];
char str2[105];
int list[6][6] = {
//	  		{  A,  C,  G,  T,  -}
	/*A*/	{  5, -1, -2, -1, -3},
	/*C*/	{ -1,  5, -3, -2, -4},
	/*G*/	{ -2, -3,  5, -2, -2},
	/*T*/	{ -1, -2, -2,  5, -1},
	/*-*/	{ -3, -4, -2, -1,  0},
};

map<char, int>m;

int dp[105][105];//dp[x][y]表示str1中1...x个字符和str2中第1...y这两个子串之间的所有匹配方式的最大利益

int main(int argc, char const *argv[])
{
	int T, len1, len2;
	scanf("%d", &T);

	m['A'] = 0;
	m['C'] = 1;
	m['G'] = 2;
	m['T'] = 3;
	m['-'] = 4;

	while (T--) {
		memset(dp, 0, sizeof(dp));
		scanf("%d%s", &len1, str1 + 1);
		scanf("%d%s", &len2, str2 + 1);

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
			dp[x][0] = dp[x - 1][0] + list[m[str1[x]]][m['-']];
		}

		// printf("↖0\t");
		for (int y = 1; y <= len2; y++) {
			dp[0][y] = dp[0][y - 1] + list[m[str2[y]]][m['-']];
			// printf("←%d\t", dp[0][y]);
		}
		// printf("\n");

		for (int x = 1; x <= len1; x++) {

			// printf("↑%d\t", dp[x][0]);

			for (int y = 1; y <= len2; y++) {
				dp[x][y] = MAX(
				               dp[x - 1][y - 1] + list[m[str1[x]]][m[str2[y]]],
				               dp[x - 1][y] + list[m[str1[x]]][m['-']],
				               dp[x][y - 1] + list[m['-']][m[str2[y]]]
				           );

//取消所有额外注释可打印流程
				/*
								if (dp[x - 1][y - 1] + list[m[str1[x]]][m[str2[y]]]
								        >= dp[x - 1][y] + list[m[str1[x]]][m['-']]) {
									if (dp[x - 1][y - 1] + list[m[str1[x]]][m[str2[y]]]
									        >=
									        dp[x][y - 1] + list[m['-']][m[str2[y]]]) {
										printf("↖%d\t", dp[x][y]);
									} else {
										printf("←%d\t", dp[x][y]);
									}
								} else {
									if (dp[x - 1][y] + list[m[str1[x]]][m['-']]
									        >=
									        dp[x][y - 1] + list[m['-']][m[str2[y]]]) {
										printf("↑%d\t", dp[x][y]);
									} else {
										printf("←%d\t", dp[x][y]);

									}
								}
				*/

			}

			/*
						printf("\n");
			*/

		}
		printf("%d\n", dp[len1][len2]);

		/**
		*
		*	in:
		*
		*	2
		*	7 AGTGATG
		*	5 GTTAG
		*	7 AGCTATT
		*	9 AGCTTTAAA
		*
		*	out:
		*
		*	↖0		←-2		←-3		←-4		←-7		←-9
		*	↑-3		↖-2		↖-3		↖-4		↖1		←-1
		*	↑-5		↖2		←1		←0		↑-1		↖6
		*	↑-6		↑1		↖7		↖6		←3		↑5
		*	↑-8		↖-1		↑5		↖5		↖4		↖8
		*	↑-11	↑-4		↑2		↖4		↖10		←8
		*	↑-12	↑-5		↖1		↖7		↑9		↖8
		*	↑-14	↖-7		↑-1		↑5		↑7		↖14
		*
		*	14
		*
		*	↖0		←-3		←-5		←-9		←-10	←-11	←-12	←-15	←-18	←-21
		*	↑-3		↖5		←3		←-1		←-2		←-3		←-4		↖-7		↖-10	↖-13
		*	↑-5		↑3		↖10		←6		←5		←4		←3		←0		←-3		←-6
		*	↑-9		↑-1		↑6		↖15		←14		←13		←12		←9		←6		←3
		*	↑-10	↑-2		↑5		↑14		↖20		↖19		↖18		←15		←12		←9
		*	↑-13	↖-5		↑2		↑11		↑17		↖19		↖18		↖23		↖20		↖17
		*	↑-14	↑-6		↑1		↑10		↖16		↖22		↖24		↑22		↖22		↖19
		*	↑-15	↑-7		↑0		↑9		↖15		↖21		↖27		←24		↖21		↖21
		*
		*
		*	21
		*
		*
		*
		*/

	}
	return 0;
}

```
