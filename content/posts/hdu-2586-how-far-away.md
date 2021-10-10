---
title: >-
  HDU 2586 How far away ？——树上节点最短距离，LCA， 双亲表示法+暴力从下至上追溯，孩子链表示法+（Tarjan 或
  欧拉环游RMQ+（ST 或 SegmentTree））
id: 17
aliases:
  - /blog/17/
categories:
  - Algorithm
date: 2018-03-02T15:58:51+08:00
tags:
  - HDU
  - dp
  - 树上最短距离
  - LCA
  - 树
  - 线段树
---

标题真长。。。

HDU 2586 How far away ？——树上节点最短距离，LCA， 双亲表示法+暴力从下至上追溯，孩子链表示法+（Tarjan 或 欧拉环游RMQ+（ST 或 SegmentTree））

[http://acm.hdu.edu.cn/showproblem.php?pid=2586](http://acm.hdu.edu.cn/showproblem.php?pid=2586)

## 四种解法：
\- 双亲表示法+暴力从下至上追溯
\- 孩子链表示法+Tarjan
\- 孩子链表示法+欧拉环游RMQ+ST
\- 孩子链表示法+欧拉环游RMQ+SegmentTree

## 对于建树的问题，要解决父节点和子节点的问题：

\- 第一种解法中，双亲表示法，用一个一维数组houses来储存所有节点，houses[x].fa表示该节点的父节点，当两个子树被合并造成冲突时，将其中一棵树倒置

如：
> 1    2
> ↑    ↑
> 3    4
> ↑    ↑
> 5    6

此时要连接3和4，必定会造成冲突，因为，若将3作为4的父节点（3 → 4），4就会有两个父节点，于是把4 ← 6这一支倒置成 4 → 6
于是：
> 1    2
> ↑    ↑
> 3  → 4
> ↑    ↓
> 5    6
（5成为合并以后的根元素）

\- 剩下三种解法则利用孩子链表示法，记录所有与目标节点相连接的节点（包括一个父节点和一个子节点），然后随便选取一个节点作为父节点，用dfs遍历这些连接的节点，同时用visited数组来跳过其中的父节点

# 解法1：
```
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

using namespace std;

//31ms

//双亲表示法

//当建树遇到冲突时，将冲突的一支树倒置

struct Node
{
	int disToFa;
	int fa;
};

Node houses[40005];
int visited[40005];

void add(int x, int y, int z) {
	if (!houses[x].fa) {//若x还没有父元素
		//把x挂在y下
		houses[x].fa = y;
		houses[x].disToFa = z;

	} else {

		if (!houses[y].fa) { //若y还没有父元素
			//把y挂在x下
			houses[y].fa = x;
			houses[y].disToFa = z;
		} else {
			//x和y都有父元素了

			//将x的父元素向上追溯全部变成子元素（将这一支箭头全部倒置）

			//修改前的副本
			Node temp_x = houses[x];
			Node temp_x_fa = houses[temp_x.fa];

			//把x挂在y下
			houses[x].fa = y;
			houses[x].disToFa = z;

			while (temp_x_fa.fa) {

				houses[temp_x.fa].disToFa = temp_x.disToFa;
				houses[temp_x.fa].fa = x;

				x = temp_x.fa;
				temp_x = houses[x];
				temp_x_fa = houses[temp_x.fa];

			}

		}

	}
}

int cal(int x, int y) {
//先从x开始一直追溯到根节点，沿途标记所有经过的节点（visited数组两个作用，一是用来标记是否访问过，二是用来记录从x节点出发以后走过的距离）
	int sum_x = 0;
	visited[x] = -1;

	sum_x += houses[x].disToFa;
	x = houses[x].fa;

	while (houses[x].fa) {//当未到树顶时
		visited[x] = sum_x;
		sum_x += houses[x].disToFa;
		x = houses[x].fa;
	}

	//此时x是树顶
	if (visited[x] != -1) {
		visited[x] = sum_x;
	}

	//接下来从y开始向上追溯
	int sum_y = 0;
	while (!visited[y]) {
		sum_y += houses[y].disToFa;
		y = houses[y].fa;
	}

	//根据之前留下的-1判断原始的x是否为y的父元素
	if (visited[y] == -1) {//这种情况表明y向上追溯的过程中遇到了x
		return sum_y;//直接返回y向上追溯到x的距离
	} else {//这种情况表明y追溯到了x的某一个祖先元素
		return sum_y + visited[y];//返回y向上追溯到x的距离 + 从x到这个祖先元素的距离
	}

}

int main(int argc, char const *argv[])
{
	int T, n, m, cp_n, a1, a2, a3;
	scanf("%d", &T);
	while (T--) {
		scanf("%d%d", &n, &m);

		cp_n = n;

		memset(houses, 0, sizeof(Node) * (n + 1));

		while (--n) {
			scanf("%d%d%d", &a1, &a2, &a3);

			add(a1, a2, a3);

		}

		while (m--) {
			scanf("%d%d", &a1, &a2);

			memset(visited, 0, sizeof(int) * (cp_n + 1));//每处理一个问题前刷新一次

			printf("%d\n", cal(a1, a2));

		}

	}

	return 0;
}
```

# 解法2：

```
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

using namespace std;

//31ms
//Tarjan

//孩子链表示法(链表)
//这里的孩子不一定是子节点，可能还有一个父节点，但是可以用visited数组来区别
//随便选取一个hand作为根节点，就可以建成一棵树

int hand[40005];//保存第x号房子的所有孩子节点链表的起始节点编号

struct Node//链表节点
{
	int distance;//权值
	int to;
	int next;//保存下一个Node的位置（并非指房子的编号，是节点的编号），即孩子组成的链表中的下一个节点的位置
};

Node nodes[40005 << 1];//需要两倍空间
int pos;//pos为nodes的当前可用的Node的位置编号
int disToRoot[40005];//代表到根节点的距离
// 结果 = disToRoot[x] + disToRoot[y] - 2 * disToRoot[LCA(x, y)]

//Tarjan
int fa[40005];
int visited[40005];
int qhand[40005];
Node ques[40005 << 1];
int qpos;

void addToTree(int x, int y, int z) {//表示为x号房子添加一个子节点 y ,距离为z
	//为pos号节点写入数据
	nodes[pos].to = y;
	nodes[pos].distance = z;
	nodes[pos].next = hand[x];
	hand[x] = pos;

	pos++;//当前可用的节点编号+1
}

void addToQue(int x, int y) {
	ques[qpos].to = y;
	ques[qpos].distance = 0;
	ques[qpos].next = qhand[x];
	qhand[x] = qpos;

	qpos++;
}

int tarjanFind(int x) {//并查集查找（非递归压缩路径）
	int cp_x = x;
	while (fa[x] != x) {
		x = fa[x];
	}

	while (fa[cp_x] != cp_x) {
		cp_x = fa[cp_x];
		fa[cp_x] = x;
	}

	return x;
}

void tarjan(int which) {

	visited[which] = 1;

	fa[which] = which;

	int childPos = hand[which];

	while (childPos) {

		if (visited[nodes[childPos].to]) {//跳过父元素
			childPos = nodes[childPos].next;
			continue;
		}

		disToRoot[nodes[childPos].to] = disToRoot[which] + nodes[childPos].distance;//写入到根节点的距离
		tarjan(nodes[childPos].to);

		fa[nodes[childPos].to] = which;

		childPos = nodes[childPos].next;

	}

//处理询问
	int quesPos = qhand[which];

	while (quesPos) {

		if (visited[ques[quesPos].to]) {
			ques[quesPos].distance = disToRoot[which] + disToRoot[ques[quesPos].to] - 2 * disToRoot[tarjanFind(ques[quesPos].to)];
		}

		quesPos = ques[quesPos].next;
	}

}

int main(int argc, char const *argv[])
{
	int T, n, m, a1, a2, a3;
	scanf("%d", &T);
	while (T--) {
		scanf("%d%d", &n, &m);

		memset(hand, 0, sizeof(int) * (n + 1));
		memset(qhand, 0, sizeof(int) * (n + 1));
		memset(visited, 0, sizeof(int) * (n + 1));

		pos = 1;

		while (--n) {
			scanf("%d%d%d", &a1, &a2, &a3);

			addToTree(a1, a2, a3);
			addToTree(a2, a1, a3);

		}

		qpos = 1;

		//离线算法（先收集所有问题，然后统一遍历）
		while (m--) {

			scanf("%d%d", &a1, &a2);

			//建立链表的方法和上面建树的方法类似
			addToQue(a1, a2);
			addToQue(a2, a1);

		}

		disToRoot[1] = 0;
		tarjan(1);

		for (int i = 1; i < qpos; i += 2) {
			printf("%d\n", ques[i].distance ? ques[i].distance : ques[i + 1].distance);
		}

	}

	return 0;
}
```

# 解法3：
```
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

using namespace std;

//46ms
//转化为RMQ问题_ST
//在线算法

//孩子链表示法(链表)
//这里的孩子不一定是子节点，可能还有一个父节点，但是可以用visited数组来区别
//随便选取一个hand作为根节点，就可以建成一棵树

int hand[40005];//保存第x号房子的所有孩子节点链表的起始节点编号

struct Node//链表节点
{
	int distance;//权值
	int to;
	int next;//保存下一个Node的位置（并非指房子的编号，是节点的编号），即孩子组成的链表中的下一个节点的位置
};

Node nodes[40005 << 1];//需要两倍空间

int pos;//pos为nodes的当前可用的Node的位置编号
int disToRoot[40005];//代表到根节点的距离
// 结果 = disToRoot[x] + disToRoot[y] - 2 * disToRoot[LCA(x, y)]

//RMQ
int rmq_which[40005 << 1];//RMQ数组长度约为节点数的两倍（实际上是2n-1），储存欧拉环游经过的所有节点号
int rmq_deep[40005 << 1];//储存环游中节点的深度
int rmq_first[40005];//储存循环中 x 号节点（房子）第一次出现的位置
int rmq_pos;

int visited[40005];//排除父节点

//ST
int st[40005 << 1][18]; //2的17次方大于 40005
// st[x][y] = 代表rmq_deep数组中从x开始持续长为（2的y次方）长的区间范围内的最小deep 的位置

void addToTree(int x, int y, int z) {//表示为x号房子添加一个子节点 y ,距离为z
	//为pos号节点写入数据
	nodes[pos].to = y;
	nodes[pos].distance = z;
	nodes[pos].next = hand[x];
	hand[x] = pos;

	pos++;//当前可用的节点编号+1
}

/**
* rmq函数用欧拉环游生成了rmq_which 和 rmq_deep 和 rmq_first 和 disToRoot 四个数组
*/
void rmq(int which, int deep) {
	visited[which] = 1;

	rmq_which[rmq_pos] = which;
	rmq_deep[rmq_pos] = deep;
	rmq_first[which] = rmq_pos;
	rmq_pos++;

	int childPos = hand[which];

	while (childPos) {
		if (visited[nodes[childPos].to]) {
			childPos = nodes[childPos].next;
			continue;
		}

		disToRoot[nodes[childPos].to] = disToRoot[which] + nodes[childPos].distance;

		rmq(nodes[childPos].to, deep + 1);

		rmq_which[rmq_pos] = which;
		rmq_deep[rmq_pos] = deep;
		rmq_pos++;

		childPos = nodes[childPos].next;

	}

}

//初始化st数组
void init_st() {
	for (int i = 0; i < rmq_pos; ++i) {//根据st的定义，y为0时，st[i][0] = i;
		st[i][0] = i;
	}

	for (int y = 1 ; y < 18; ++y) {
		for (int i = 0; i + (1 << y) - 1 < rmq_pos; ++i) {
			st[i][y] =	rmq_deep[st[i][y - 1]] < rmq_deep[st[i + (1 << (y - 1))][y - 1]] ? st[i][y - 1] : st[i + (1 << (y - 1))][y - 1];
		}
	}
}

// 返回rmq_deep数组区间[x, y]之间的最小元素的位置
int min_st(int x, int y) {

	if (x > y) {//保证输入的x <= y;若不满足，则反过来
		return min_st(y, x);
	}

	for (int i = 17; i >= 0; --i) {
		if (x + (1 << i) - 1 > y) {
			continue;
		}

		if (x + (1 << i) - 1 == y) {
			return st[x][i];
		} else {
			int temp = min_st(x + (1 << i), y);
			return rmq_deep[st[x][i]] < rmq_deep[temp] ? st[x][i] : temp;
		}
	}

	return 0;
}

int main(int argc, char const *argv[])
{
	int T, n, m, a1, a2, a3, first = 1;
	scanf("%d", &T);
	while (T--) {
		scanf("%d%d", &n, &m);

		memset(hand, 0, sizeof(int) * (n + 1));
		memset(visited, 0, sizeof(int) * (n + 1));

		pos = 1;

		while (--n) {
			scanf("%d%d%d", &a1, &a2, &a3);

			addToTree(a1, a2, a3);
			addToTree(a2, a1, a3);

		}

		disToRoot[1] = 0;

		//在线算法（逐个回答问题）

		rmq_pos = 0;

		rmq(1, 1);

		init_st();

		if (first) {
			first = 0;
		} else {
			printf("\n");
		}

		// for (int i = 0; i < rmq_pos; i++) {
		// 	printf("%d ", rmq_which[i]);
		// }
		// printf("\n");
		// for (int i = 0; i < rmq_pos; i++) {
		// 	printf("%d ", rmq_deep[i]);
		// }
		// printf("\n");
		// for (int i = 1; i <= 6; i++) {
		// 	printf("%d ", rmq_first[i]);
		// }
		// printf("\n");

		// for (int x = 0; x < 18; x++) {
		// 	for (int i = 0; i < rmq_pos; i++) {
		// 		printf("%d ", st[i][x]);
		// 	}
		// 	printf("\n");
		// }

		while (m--) {

			scanf("%d%d", &a1, &a2);

			printf("%d\n", disToRoot[a1] + disToRoot[a2] - 2 * disToRoot[rmq_which[min_st(rmq_first[a1], rmq_first[a2])]]);

		}

	}

	return 0;
}
```

# 解法4：
```
#include <iostream>
#include <algorithm>
#include <cstring>
#include <string>
#include <cstdio>
#include <cmath>

using namespace std;

//31ms
//转化为RMQ问题_Segment_Tree

/**
*	注意线段树需要4倍空间
*	注意线段树需要4倍空间
*	注意线段树需要4倍空间
*/

//在线算法

//孩子链表示法(链表)
//这里的孩子不一定是子节点，可能还有一个父节点，但是可以用visited数组来区别
//随便选取一个hand作为根节点，就可以建成一棵树

int hand[40005];//保存第x号房子的所有孩子节点链表的起始节点编号

struct Node//链表节点
{
	int distance;//权值
	int to;
	int next;//保存下一个Node的位置（并非指房子的编号，是节点的编号），即孩子组成的链表中的下一个节点的位置
};

Node nodes[40005 << 1];//需要两倍空间

int pos;//pos为nodes的当前可用的Node的位置编号
int disToRoot[40005];//代表到根节点的距离
// 结果 = disToRoot[x] + disToRoot[y] - 2 * disToRoot[LCA(x, y)]

//RMQ
int rmq_which[40005 << 1];//RMQ数组长度约为节点数的两倍（实际上是2n-1），储存欧拉环游经过的所有节点号
int rmq_deep[40005 << 1];//储存环游中节点的深度
int rmq_first[40005];//储存循环中 x 号节点（房子）第一次出现的位置
int rmq_pos;

int visited[40005];//排除父节点

//Segment_Tree
struct SegNode
{
	int left;
	int right;
	int minPos;//储存[left, right]区间内deep最小值所处的位置
};

//线段树需要原基础数组长度四倍的空间
SegNode segs[40005 << 3];//从1开始

void addToTree(int x, int y, int z) {//表示为x号房子添加一个子节点 y ,距离为z
	//为pos号节点写入数据
	nodes[pos].to = y;
	nodes[pos].distance = z;
	nodes[pos].next = hand[x];
	hand[x] = pos;

	pos++;//当前可用的节点编号+1
}

/**
* rmq函数用欧拉环游生成了rmq_which 和 rmq_deep 和 rmq_first 和 disToRoot 四个数组
*/
void rmq(int which, int deep) {
	visited[which] = 1;

	rmq_which[rmq_pos] = which;
	rmq_deep[rmq_pos] = deep;
	rmq_first[which] = rmq_pos;
	rmq_pos++;

	int childPos = hand[which];

	while (childPos) {
		if (visited[nodes[childPos].to]) {
			childPos = nodes[childPos].next;
			continue;
		}

		disToRoot[nodes[childPos].to] = disToRoot[which] + nodes[childPos].distance;

		rmq(nodes[childPos].to, deep + 1);

		rmq_which[rmq_pos] = which;
		rmq_deep[rmq_pos] = deep;
		rmq_pos++;

		childPos = nodes[childPos].next;

	}

}

//初始化segment数组
void build_seg(int spos, int left, int right) {
	// printf("spos -> %d\n", spos);
	segs[spos].left = left;
	segs[spos].right = right;

	if (left == right) {
		segs[spos].minPos = left;
		return;
	}

	build_seg(spos << 1, left, (left + right) / 2);
	build_seg((spos << 1) | 1, ((left + right) / 2) + 1, right);

	segs[spos].minPos = rmq_deep[segs[spos << 1].minPos] < rmq_deep[segs[(spos << 1) | 1].minPos] ? segs[spos << 1].minPos : segs[(spos << 1) | 1].minPos;

}

// 返回rmq_deep数组区间[x, y]之间的最小元素的位置
int min_seg(int pos, int x, int y) {
	if (x == segs[pos].left && y == segs[pos].right) {
		return segs[pos].minPos;
	} else if (y <= ((segs[pos].left + segs[pos].right) / 2)) {
		return min_seg(pos << 1, x, y);
	} else if (x > ((segs[pos].left + segs[pos].right) / 2)) {
		return min_seg((pos << 1) | 1, x, y);
	} else {
		int temp1, temp2;
		temp1 = min_seg(pos << 1, x, (segs[pos].left + segs[pos].right) / 2);
		temp2 = min_seg((pos << 1) | 1, ((segs[pos].left + segs[pos].right) / 2) + 1, y);

		return rmq_deep[temp1] < rmq_deep[temp2] ? temp1 : temp2;
	}
}

int main(int argc, char const *argv[])
{
	int T, n, m, a1, a2, a3, first = 1;
	scanf("%d", &T);
	while (T--) {
		scanf("%d%d", &n, &m);

		memset(hand, 0, sizeof(int) * (n + 1));
		memset(visited, 0, sizeof(int) * (n + 1));

		pos = 1;

		while (--n) {
			scanf("%d%d%d", &a1, &a2, &a3);

			addToTree(a1, a2, a3);
			addToTree(a2, a1, a3);

		}

		disToRoot[1] = 0;

		//在线算法（逐个回答问题）

		rmq_pos = 0;

		rmq(1, 1);

		// printf("rmq_pos -> %d\n", rmq_pos);

		build_seg(1, 0, rmq_pos - 1);

		if (first) {//好像没有空行也能过
			first = 0;
		} else {
			printf("\n");
		}

		// for (int i = 0; i < rmq_pos; i++) {
		// 	printf("%d ", rmq_which[i]);
		// }
		// printf("\n");
		// for (int i = 0; i < rmq_pos; i++) {
		// 	printf("%d ", rmq_deep[i]);
		// }
		// printf("\n");
		// for (int i = 1; i <= 6; i++) {
		// 	printf("%d ", rmq_first[i]);
		// }
		// printf("\n");

		while (m--) {

			scanf("%d%d", &a1, &a2);

			if (rmq_first[a1] < rmq_first[a2]) {

				printf("%d\n", disToRoot[a1] + disToRoot[a2] - 2 * disToRoot[rmq_which[min_seg(1, rmq_first[a1], rmq_first[a2])]]);
			} else {
				printf("%d\n", disToRoot[a1] + disToRoot[a2] - 2 * disToRoot[rmq_which[min_seg(1, rmq_first[a2], rmq_first[a1])]]);
			}

		}

	}

	return 0;
}
```
