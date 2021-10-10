---
title: CodeForces 697D 树+概率
id: 5
aliases:
  - /blog/5/
categories:
  - 算法
date: 2018-02-01T23:34:57+08:00
tags:
---

[原题链接](http://codeforces.com/problemset/problem/697/D)

```
D. Puzzles
time limit per test
1 second
memory limit per test
256 megabytes
input
standard input
output
standard output

Barney lives in country USC (United States of Charzeh). USC has n cities numbered from 1 through n and n - 1 roads between them. Cities and roads of USC form a rooted tree (Barney's not sure why it is rooted). Root of the tree is the city number 1\. Thus if one will start his journey from city 1, he can visit any city he wants by following roads.

Some girl has stolen Barney's heart, and Barney wants to find her. He starts looking for in the root of the tree and (since he is Barney Stinson not a random guy), he uses a random DFS to search in the cities. A pseudo code of this algorithm is as follows:

let starting_time be an array of length n
current_time = 0
dfs(v):
	current_time = current_time + 1
	starting_time[v] = current_time
	shuffle children[v] randomly (each permutation with equal possibility)
	// children[v] is vector of children cities of city v
	for u in children[v]:
		dfs(u)

As told before, Barney will start his journey in the root of the tree (equivalent to call dfs(1)).

Now Barney needs to pack a backpack and so he wants to know more about his upcoming journey: for every city i, Barney wants to know the expected value of starting_time[i]. He's a friend of Jon Snow and knows nothing, that's why he asked for your help.
Input

The first line of input contains a single integer n (1 ≤ n ≤ 105) — the number of cities in USC.

The second line contains n - 1 integers p2, p3, ..., pn (1 ≤ pi < i), where pi is the number of the parent city of city number i in the tree, meaning there is a road between cities numbered pi and i in USC.
Output

In the first and only line of output print n numbers, where i-th number is the expected value of starting_time[i].

Your answer for each city will be considered correct if its absolute or relative error does not exceed 10 - 6.
Examples
Input

7
1 2 1 1 4 4

Output

1.0 4.0 5.0 3.5 4.5 5.0 5.0 

Input

12
1 1 2 2 4 4 3 3 1 10 8

Output

1.0 5.0 5.5 6.5 7.5 8.0 8.0 7.0 7.5 6.5 7.5 8.0 
```


```
#include <iostream>
#include <cstdio>
#include <set>
//multiset的定义在set头文件中

using namespace std;

int data[100005][2];//[0]自身以及子节点的数量[1]父节点
double ans[100005];

struct Node {
	int x;//父节点
	int y;//子节点

	Node(int x, int y): x(x), y(y) {
	}
	int operator < (Node const & n) const {//倒序
		return x > n.x;
	}
};

multiset<Node> ms;

int main(int argc, char const *argv[])
{

	int n, temp;
	scanf("%d", &n);
	data[1][0] = 1;
	for (int i = 2; i <= n; i++) {
		scanf("%d", &temp);
		data[i][0] = 1;
		data[i][1] = temp;
		Node n(temp, i);
		ms.insert(n);
	}

	// 从树的最底开始上升
	int cou = 0;
	for (multiset<Node>::iterator i = ms.begin(); i != ms.end(); ++i) {
		data[i->x][0] += data[i->y][0];
	}

	ans[1] = 1.0;
	printf("1.0");
	for (int i = 2; i <= n; i++) {
		/**
		* 第i个节点的期望 == 它的父节点的期望 + 在它自身的耗时(1) + 第i个节点的兄弟节点及它拓展的子节点耗时的期望(即兄弟节点及它拓展的子节点数 * 0.5)
		* (兄弟节点及它拓展的子节点数 == i 的父节点 - i 节点拓展的树的所有节点(包括i) - 1(父节点自身))，
		* 这些节点每一个要么在i之前被遍历，要么在i之后，于是期望值乘以0.5
		*/
		ans[i] = ans[data[i][1]] + 1 + (data[data[i][1]][0] - 1 - data[i][0]) * 0.5;
		printf(" %.1f", ans[i]);
	}

	return 0;
}

```
