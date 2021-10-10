---
title: 最长递增子列问题的另一种思路——转化为LCS问题
id: 28
aliases:
  - /blog/28/
categories:
  - Algorithm
date: 2018-02-06T21:11:32+08:00
tags:
  - LCS
---

## 利用LCS的解题思路可以解决最长递增子列的问题顺便求出该递增序列


> 例如
> list1 = [1, 2, 3, 1, -1, 0, 4, 5]
> 将其排序得
> list2 = [-1, 0, 1, 1, 2, 3, 4, 5]
> 则问题转化为
> 求list1和list2的最长的不要求连续的公共子列及其长度

资料：
[http://blog.csdn.net/u013178472/article/details/54926531](http://blog.csdn.net/u013178472/article/details/54926531)
