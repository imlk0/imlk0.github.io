---
title: HDU 1166 敌兵布阵——线段树，树状数组
id: 13
aliases:
  - /blog/13/
categories:
  - Algorithm
date: 2018-02-06T17:33:38+08:00
tags:
  - 线段树
---

这题本来我打算用前缀数组实现源数据的处理，并把更变用map<int ,int>实现，发现后来还是超时了；

借机学习了一下线段树，虽然没怎么看懂，但大概还是理解了一点；
这题用 指针构成的线段树 和 数组构成的线段树 分别来实现了一下
资料：
线段树从零开始 - CSDN博客
[http://blog.csdn.net/zearot/article/details/52280189](http://blog.csdn.net/zearot/article/details/52280189)
线段树详解 （原理，实现与应用） - CSDN博客
[http://blog.csdn.net/zearot/article/details/48299459](http://blog.csdn.net/zearot/article/details/48299459)
看到有人用树状数组实现，学习了一下树状数组，代码贴在最后：
资料：
树状数组入门
[https://www.cnblogs.com/hsd-/p/6139376.html](https://www.cnblogs.com/hsd-/p/6139376.html)

题目来源：[http://acm.hdu.edu.cn/showproblem.php?pid=1166](http://acm.hdu.edu.cn/showproblem.php?pid=1166)


> 敌兵布阵
> Time Limit: 2000/1000 MS (Java/Others)    Memory Limit: 65536/32768 K (Java/Others)
> Total Submission(s): 106625    Accepted Submission(s): 44789
> 
> Problem Description
> C国的死对头A国这段时间正在进行军事演习，所以C国间谍头子Derek和他手下Tidy又开始忙乎了。A国在海岸线沿直线布置了N个工兵营地,Derek和Tidy的任务就是要监视这些工兵营地的活动情况。由于采取了某种先进的监测手段，所以每个工兵营地的人数C国都掌握的一清二楚,每个工兵营地的人数都有可能发生变动，可能增加或减少若干人手,但这些都逃不过C国的监视。
> 中央情报局要研究敌人究竟演习什么战术,所以Tidy要随时向Derek汇报某一段连续的工兵营地一共有多少人,例如Derek问:“Tidy,马上汇报第3个营地到第10个营地共有多少人!”Tidy就要马上开始计算这一段的总人数并汇报。但敌兵营地的人数经常变动，而Derek每次询问的段都不一样，所以Tidy不得不每次都一个一个营地的去数，很快就精疲力尽了，Derek对Tidy的计算速度越来越不满:"你个死肥仔，算得这么慢，我炒你鱿鱼!”Tidy想：“你自己来算算看，这可真是一项累人的工作!我恨不得你炒我鱿鱼呢!”无奈之下，Tidy只好打电话向计算机专家Windbreaker求救,Windbreaker说：“死肥仔，叫你平时做多点acm题和看多点算法书，现在尝到苦果了吧!”Tidy说："我知错了。。。"但Windbreaker已经挂掉电话了。Tidy很苦恼，这么算他真的会崩溃的，聪明的读者，你能写个程序帮他完成这项工作吗？不过如果你的程序效率不够高的话，Tidy还是会受到Derek的责骂的.
> 
> Input
> 第一行一个整数T，表示有T组数据。
> 每组数据第一行一个正整数N（N<=50000）,表示敌人有N个工兵营地，接下来有N个正整数,第i个正整数ai代表第i个工兵营地里开始时有ai个人（1<=ai<=50）。
> 接下来每行有一条命令，命令有4种形式：
> (1) Add i j,i和j为正整数,表示第i个营地增加j个人（j不超过30）
> (2)Sub i j ,i和j为正整数,表示第i个营地减少j个人（j不超过30）;
> (3)Query i j ,i和j为正整数,i<=j，表示询问第i到第j个营地的总人数;
> (4)End 表示结束，这条命令在每组数据最后出现;
> 每组数据最多有40000条命令
> 
> Output
> 对第i组数据,首先输出“Case i:”和回车,
> 对于每个Query询问，输出一个整数并回车,表示询问的段中的总人数,这个数保持在int以内。
> 
> Sample Input
> 
> 1
> 10
> 1 2 3 4 5 6 7 8 9 10
> Query 1 3
> Add 3 6
> Query 2 7
> Sub 10 2
> Add 6 3
> Query 3 10
> End 
> 
> Sample Output
> 
> Case 1:
> 6
> 33
> 59
> 
> Author
> Windbreaker
> 
> Recommend
> Eddy   |   We have carefully selected several similar problems for you:  1394 1698 1754 1542 1540 


指针线段树：
```
#include <iostream>
#include <cstdio>
#include <cstring>

using namespace std;

// 线段树

struct Node {
	int lp;
	int rp;
	int mid;
	int sum;
	Node* left;
	Node* right;
	Node(int l, int r): lp(l), rp(r), mid((l + r) / 2), left(NULL), right(NULL) {}//new初始化的内存不一定自动填0
};

int list[50005];//从1开始

int T, N, a, b;

Node* buildTree(int l, int r) {
	Node* p = new Node(l, r);
	if (l == r) {
		p->sum = list[l];
		return p;
	}
	p->left = buildTree(l, p->mid);
	p->right = buildTree(p->mid + 1, r);

	p->sum = p->left->sum + p->right->sum;
	return p;
}

void treeAdd(Node *which, int where, int what) {

	if (which->left != NULL && which->right != NULL) {
		treeAdd((where <= which->mid) ? which->left : which->right, where, what);
	}
	which->sum += what;
}

int calSum(Node * which, int from, int to) {

	if (from == which->lp && to == which->rp) {
		return which->sum;
	}

	if (from <= which->mid) {
		if (to > which->mid) {//横跨
			return calSum(which->left, from, which->mid) + calSum(which->right, which->mid + 1, to);
		} else {//全在左边
			return calSum(which->left, from, to);
		}
	} else {//全在右边
		return calSum(which->right, from, to);
	}

	return 0;
}

void del(Node * which) {
	if (which->left) {
		del(which->left);
	}
	if (which->right) {
		del(which->right);
	}

	delete which;
}

int main(int argc, char const *argv[])
{

	char cmd[10];
	scanf("%d", &T);

	for (int t = 1; t <= T; t++) {

		memset(list, 0, sizeof(list));

		scanf("%d", &N);

		for (int i = 0; i < N; i++) {
			scanf("%d", list + i);
		}

		Node* root = buildTree(0, N - 1);

		printf("Case %d:\n", t);
		while (1) {
			scanf("%s", cmd);
			if ('E' == cmd[0]) {
				break;
			}
			scanf("%d%d", &a, &b);
			switch (cmd[0]) {
			case 'Q':
				printf("%d\n", calSum(root, a - 1, b - 1));
				break;
			case 'A':
				list[a - 1] += b;
				treeAdd(root, a - 1, b);
				break;
			case 'S':
				list[a - 1] -= b;
				treeAdd(root, a - 1, -b);
				break;
			}
		}

		del(root);
		root = NULL;

	}

	return 0;
}
```
自定义结构体组成的数组实现线段树：
```
#include <iostream>
#include <cstdio>
#include <cstring>

using namespace std;

// 线段树

struct Node {
	int lp;
	int rp;
	int mid;
	int sum;
} nodes[50005 << 2];//空间为原数组的四倍长，1储存根元素，对于第k个节点，K<<1表示左支，(k<<1)|1表示右支

int list[50005];//从0开始

int T, N, a, b;

int buildTree(int which, int l, int r) {

	nodes[which].lp = l;
	nodes[which].rp = r;
	nodes[which].mid = ((l + r) >> 1);

	if (l == r) {
		nodes[which].sum = list[l];

	} else {
		nodes[which].sum += buildTree(which << 1, l, (l + r) >> 1);
		nodes[which].sum += buildTree((which << 1) | 1, ((l + r) >> 1) + 1, r);
	}

	return nodes[which].sum;
}

void treeAdd(int which, int where, int what) {

	if (nodes[which].lp != nodes[which].rp) {
		treeAdd((where <= nodes[which].mid) ? which << 1 : (which << 1) | 1, where, what);
	}
	nodes[which].sum += what;
}

int calSum(int which, int from, int to) {

	// printf("from_%d,to_%d,and_now_is_%d,%d\n", from, to, nodes[which].lp, nodes[which].rp);
	if (from == nodes[which].lp && to == nodes[which].rp) {
		return nodes[which].sum;
	}

	if (from <= nodes[which].mid) {
		if (to > nodes[which].mid) {//横跨
			return calSum(which << 1, from, nodes[which].mid) + calSum((which << 1) | 1, nodes[which].mid + 1, to);
		} else {//全在左边
			return calSum(which << 1, from, to);
		}
	} else {//全在右边
		return calSum((which << 1) | 1, from, to);
	}

	return 0;
}

int main(int argc, char const *argv[])
{

	char cmd[10];
	scanf("%d", &T);

	for (int t = 1; t <= T; t++) {

		memset(list, 0, sizeof(list));
		memset(nodes, 0, sizeof(nodes));

		scanf("%d", &N);

		for (int i = 0; i < N; i++) {
			scanf("%d", list + i);
		}

		buildTree(1, 0, N - 1);

		printf("Case %d:\n", t);
		while (1) {
			scanf("%s", cmd);
			if ('E' == cmd[0]) {
				break;
			}
			scanf("%d%d", &a, &b);
			switch (cmd[0]) {
			case 'Q':
				printf("%d\n", calSum(1, a - 1, b - 1));
				break;
			case 'A':
				list[a - 1] += b;
				treeAdd(1, a - 1, b);
				break;
			case 'S':
				list[a - 1] -= b;
				treeAdd(1, a - 1, -b);
				break;
			}
		}

	}

	return 0;
}
```

树状数组实现：代码量超少！！！
```
#include <iostream>
#include <cstdio>
#include <cstring>

//Accept

#define lowbit(x) (x&(-x))

//lowbit(x) 其实代表了第x号节点最底层代表的区间长度

using namespace std;

/**
*	c[x]
*															1000
*							   /————————————————————————————[8]
*							  /								 |
*							100								 |
*			   /————————————[4]				   /————————————[ ]
*			  /				 |				  /				 |
*			010				 |				110				 |
*	   /————[2]		   /————[ ]		   /————[6]		   /————[ ]
*	  /		 |		  /		 |		  /		 |		  /		 |
*	001		 |		011		 |		101		 |		111		 |
*	[1]		[ ]		[3]		[ ]		[5]		[ ]		[7]		[ ]
*/
int c[50005];//树状数组,从1开始
// c[i] = data[i - 2 ^ k + 1 ... i];

int data[50005];//存储原始数据,从1开始

int s[50005];//前缀数组,在init时用到,从1开始

int T, N, a, b;

int calSum(int where) {//返回从data[1...where]
	int su = 0;
	while (where) {
		su += c[where];
		where -= lowbit(where);
	}
	return su;
}

void add(int where, int what) {
	while (where <= N) {
		c[where] += what;
		where += lowbit(where);
	}
}

int init() {
	int sum = 0;
	// for (int i = 1; i <= N; i++) {
	// 	for (int x = i - lowbit(i) + 1; x <= i; x++) {
	// 		c[i] += data[x];
	// 	}
	// }
	// 用前缀数组来进行优化：
	for (int i = 1; i <= N; i++) {
		c[i] = s[i] - s[i - lowbit(i)];
	}

}

int main(int argc, char const *argv[])
{

	char cmd[10];
	scanf("%d", &T);

	for (int t = 1; t <= T; t++) {

		memset(c, 0, sizeof(c));
		memset(data, 0, sizeof(data));
		memset(s, 0, sizeof(s));

		scanf("%d", &N);

		for (int i = 1; i <= N; i++) {
			scanf("%d", data + i);
			s[i] = s[i - 1] + data[i];
		}

		init();

		printf("Case %d:\n", t);
		for (;;) {
			scanf("%s", cmd);
			if ('E' == cmd[0]) {
				break;
			}
			scanf("%d%d", &a, &b);
			switch (cmd[0]) {
			case 'Q':
				printf("%d\n", calSum(b) - calSum(a - 1));
				break;
			case 'A':
				add(a, b);
				break;
			case 'S':
				add(a, -b);
				break;
			}
		}
	}

	return 0;
}
```
