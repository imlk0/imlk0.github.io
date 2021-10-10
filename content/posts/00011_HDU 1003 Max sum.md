---
title: HDU 1003 Max sum——分治法的应用，动态规划，前缀数组
id: 11
aliases:
  - /blog/11/
categories:
  - Algorithm
date: 2017-12-06T23:10:33+08:00
tags:
  - HDU
  - 分治法
---

原题： [http://acm.hdu.edu.cn/showproblem.php?pid=1003](http://acm.hdu.edu.cn/showproblem.php?pid=1003)

看到这题的时候一脸懵逼，网上寻找解答，发现都讲的不详细，变量声明也很短，根本看不出是什么用途，这里给出了我的解答，参考了网上各位大神的方法，加上了注释，方便学习。

##**0x00 分治法解题**
```
#include <stdio.h>

struct Sequence
{
	//表示一个数组

	int sum;//数组元素之和
	int leftPosition;//数组左边界位置
	int rightPosition;//数组右边界位置
};

/*
	求最大子列：

	首先明确：
		给定一个数列
		其最大子列的范围，要么包括正中间的位置，要么全在最中间位置的左边，要么全在最中间位置的右边
		这三种情况在迭代函数中分别处理
*/

struct Sequence getMaxSequence(int * sourceSequence, int leftPosition, int rightPosition) {

	// printf("into： %d, %d\n",leftPosition,rightPosition);
	int mediumPosition;

	//范围：[leftPosition, rightPosition]
	if (leftPosition == rightPosition) {
		//给定范围内的子数列只有一个元素,构造一个struct sequence来描述;
		struct Sequence sequence;
		sequence.leftPosition = leftPosition;

		sequence.rightPosition = rightPosition;
		sequence.sum = sourceSequence[leftPosition];
		// printf("return: %d, %d\n",sequence.leftPosition,sequence.rightPosition);

		return sequence;
		    //将这个元素返回
	}

	//取得中间位置
	mediumPosition = (leftPosition + rightPosition) / 2;

	//构造三种struct来保存三种情况的返回值；
	struct Sequence leftSequence;
	struct Sequence rightSequence;
	struct Sequence aroundSequence;

	leftSequence = getMaxSequence(sourceSequence, leftPosition, mediumPosition);

	rightSequence = getMaxSequence(sourceSequence, mediumPosition + 1, rightPosition);

	//第三种情况下，先从中间向左边查找找出最大的和，再从中间向右边查找找出最大的和，相加得到横跨中间位置的最大值及范围
	//先是左边
	//先保存向左边出发遇到的第一个值
	int leftMaxSumTmp = sourceSequence[mediumPosition];
	//并保存该值的位置
	aroundSequence.leftPosition = mediumPosition;

	int leftSumTmp = 0;
	for (int index = mediumPosition; index >= leftPosition; index--) {
		leftSumTmp = leftSumTmp + sourceSequence[index];
		if (leftSumTmp >= leftMaxSumTmp) {
			//如果发现从中间到左边某一项的所有值之和比leftMaxSumTmp更大了,就更新leftMaxSumTmp
			//并记录此位置到aroundSequence的leftPosition字段
			leftMaxSumTmp = leftSumTmp;
			aroundSequence.leftPosition = index;
		}

	}
	//再是右边
	//先保存向右边出发遇到的第一个值(因为到这里leftPosition和rightPosition不相等所以meiumPosition + 1（一定小于等于rightPosition）一定没有超过范围：[leftPosition, rightPosition])，不加if
	int rightMaxSumTmp = sourceSequence[mediumPosition + 1];
	//保存该值的位置
	aroundSequence.rightPosition = mediumPosition + 1;

	int rightSumTmp = 0;
	for (int index = mediumPosition + 1; index <= rightPosition; index++) {
		rightSumTmp = rightSumTmp + sourceSequence[index];
		if (rightSumTmp >= rightMaxSumTmp) {
			//如果发现从中间到右边某一项的所有值之和比rightMaxSumTmp更大了,就更新rightMaxSumTmp
			//并记录此位置到aroundSequence的rightPosition字段
			rightMaxSumTmp = rightSumTmp;
			aroundSequence.rightPosition = index;
		}

	}

	aroundSequence.sum = leftMaxSumTmp + rightMaxSumTmp;

	//三选一返回，选sum最长的那个返回

	// printf("return: %d, %d\n",finalSequence.leftPosition,finalSequence.rightPosition);
	return (leftSequence.sum > rightSequence.sum) ? ((leftSequence.sum > aroundSequence.sum) ? leftSequence : aroundSequence) : ((rightSequence.sum > aroundSequence.sum) ? rightSequence : aroundSequence);

}
int main() {
	int numOfCase , indexOfCase = 1,lengthOfSquence;
	scanf("%d", &numOfCase);
	while (indexOfCase <= numOfCase) {
		scanf("%d",&lengthOfSquence);
		int sourceSequence[100000];
		for(int index = 0;index <lengthOfSquence;index++){
			scanf("%d",sourceSequence + index); 
		}
		struct Sequence aimSequence =  getMaxSequence(sourceSequence,0,lengthOfSquence - 1);
		printf("Case %d:\n%d %d %d\n", indexOfCase ,aimSequence.sum,aimSequence.leftPosition + 1,aimSequence.rightPosition + 1);
		if(indexOfCase != numOfCase){
			printf("\n");
		}
		indexOfCase++;
	}

	return 0;
}
```

寒假看到这样一篇文章，讲的很详细
[http://conw.net/archives/9/#comment-25](http://conw.net/archives/9/#comment-25)


##**0x01 动态规划**

```
#include <iostream>
#include <cstdio>
#include <cstring>

#define iinf 1e9

using namespace std;

// O(n)AC

// 动态规划
// 原先维护一个dp数组，dp[i]保存以第i个位子结尾的所有子列的最大和
// dp[i] = list[i] + max(dp[i - 1], 0);
// 自处省略这个数组，用两个变量来实现

int main(int argc, char const *argv[])
{

	int T, N, last, now, ans, startpos, l, r;
	scanf("%d", &T);
	for (int j = 1; j <= T; j++) {
		last = -1;
		ans = -iinf;
		l = 1;
		r = 1;
		scanf("%d", &N);

		for (int i = 1; i <= N; i++) {
			scanf("%d", &now);
			if (last >= 0) {
				last = now + last;

			} else {
				last = now;
				startpos = i;

			}

			if (last > ans) {
				ans = last;
				l = startpos;
				r = i;
			}

		}

		if (j == 1) {
			printf("Case 1:\n");
		} else {
			printf("\nCase %d:\n", j);
		}

		printf("%d %d %d\n", ans, l, r);

	}

	return 0;
}

```


##**0x02 结合优化后的前缀数组**

用这种用法的人似乎更多

```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <algorithm>

#define iinf 1e9

using namespace std;

// O(n)AC

// 另一种结合前缀数组的方法
// data[i] = list[0...(i - 1)];
// data数组从1开始避免对边界的判断
// 则list[x...y] = data[y + 1] - data[x];
// i作为循环变量
// 维护data[i]的最小值mi，更新ans的最大值
// mi = min(mi, data[i])
// ans = max(data[i] - mi, ans)
// 可知若以第y个元素结尾的所有子列中list[x...y]为最优解，那么data[x]一定是data[1],data[2],data[3]...data[y](注意这里没有data[y+1],因为至少要有一个元素)中的最小值

int main(int argc, char const *argv[])
{

	int T, N, sum, now, ans, min, minpos, l, r;
	scanf("%d", &T);
	for (int j = 1; j <= T; j++) {
		sum = 0;
		ans = -iinf;
		min = 0;
		minpos = 0;
		l = 1;
		r = 1;
		scanf("%d", &N);

		for (int i = 1; i <= N; i++) {
			scanf("%d", &now);
			sum += now;
			if (sum - min > ans) {//更新答案，这里使用的是上一次循环的min值
				r = i;
				l = minpos + 1;
				ans = sum - min;
			}
			if (sum < min) {//该判断语句不可和上一句调换，否则将可能出现最优解的数列长度为0；
				min = sum;//更新本次循环的min，为在下一循环中使用到
				minpos = i;
			}
		}

		if (j == 1) {
			printf("Case 1:\n");
		} else {
			printf("\nCase %d:\n", j);
		}

		printf("%d %d %d\n", ans, l, r);

	}

	return 0;
}
```
