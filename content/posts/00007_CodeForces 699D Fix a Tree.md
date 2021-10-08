---
title: CodeForces 699D Fix a Tree——并查集优化 给出所有节点的父节点（有向图），用最少的修改生成一颗合法的树（环的判断，去环）
id: 7
categories:
  - 未分类
date: 2018-02-08 18:24:54
tags:
---

```
D. Fix a Tree
time limit per test
2 seconds
memory limit per test
256 megabytes
input
standard input
output
standard output

A tree is an undirected connected graph without cycles.

Let's consider a rooted undirected tree with n vertices, numbered 1 through n. There are many ways to represent such a tree. One way is to create an array with n integers p1, p2, ..., pn, where pi denotes a parent of vertex i (here, for convenience a root is considered its own parent).
For this rooted tree the array p is [2, 3, 3, 2].

Given a sequence p1, p2, ..., pn, one is able to restore a tree:

    There must be exactly one index r that pr = r. A vertex r is a root of the tree.
    For all other n - 1 vertices i, there is an edge between vertex i and vertex pi. 

A sequence p1, p2, ..., pn is called valid if the described procedure generates some (any) rooted tree. For example, for n = 3 sequences (1,2,2), (2,3,1) and (2,1,3) are not valid.

You are given a sequence a1, a2, ..., an, not necessarily valid. Your task is to change the minimum number of elements, in order to get a valid sequence. Print the minimum number of changes and an example of a valid sequence after that number of changes. If there are many valid sequences achievable in the minimum number of changes, print any of them.
Input

The first line of the input contains an integer n (2 ≤ n ≤ 200 000) — the number of vertices in the tree.

The second line contains n integers a1, a2, ..., an (1 ≤ ai ≤ n).
Output

In the first line print the minimum number of elements to change, in order to get a valid sequence.

In the second line, print any valid sequence possible to get from (a1, a2, ..., an) in the minimum number of changes. If there are many such sequences, any of them will be accepted.
Examples
Input

4
2 3 3 4

Output

1
2 3 4 4 

Input

5
3 2 2 5 3

Output

0
3 2 2 5 3 

Input

8
2 3 5 4 1 6 6 7

Output

2
2 3 7 8 1 6 6 7
```


##**0x00**

**这题我的第一种解法就是先将多个树合并到一起，然后遍历每一个节点，暴力搜寻环，类似dfs，不断向父元素递进，用一个set储存途经的所有元素，对于查找到节点i时，判断它的父元素在set中是否出现了，如果出现了就说明成了环，然后设置节点i的父节点为一个统一的根节点
为了优化速度，引入一个visited数组记录某个节点是否已经访问过，如果访问过那么下一次遇到的时候就直接结束向父元素的递进**


```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cmath>
#include <set>

using namespace std;

// AC
//200ms

set<int> line;//缓存查找过程中经过的所有元素,耗时高

int n, changes = 0;
int root = 0;

int fa[200005];//这个数组作为最后的输出结果
int visited[200005];//优化

void check(int i) {//检查是否有环出现

	if (!line.empty()) {
		line.clear();
	}

	while (fa[i] != i) {//未到达树顶端时不断循环

		visited[i] = 1;

		if (line.count(fa[i])) {//若找到环
			changes++;//改变次数+1
			if (!root) {//若还没有根元素
				root = i;// 将此时的i作为根元素
			}

			fa[i] = root;//把当前元素挂到根元素下

			return;//退出循环

		} else {//若这一步也没出现环
			line.insert(i);//把当前元素加到set中
			i = fa[i];// 迭代
			if (visited[i]) { //若已经拜访过了,就直接退出，这一步优化很关键！
				return;
			}
		}

	}

}

int main(int argc, char const *argv[])
{
	scanf("%d", &n);

	for (int i = 1; i <= n; ++i) {
		scanf("%d", fa + i);
		if (fa[i] == i) {
			if (root) { //若此前已经有根节点
				fa[i] = root;
				changes++;
			} else {
				root = i;
			}
		}
	}

	for (int i = 1; i <= n; ++i) {
		if (!visited[i]) {
			check(i);
		}
	}

	printf("%d\n", changes);

	printf("%d", fa[1]);

	for (int i = 2; i <= n; ++i) {
		printf(" %d", fa[i]);
	}

	printf("\n");
	return 0;
}
```



##**0x01**
**我的第二种解法是结合并查集**

**思考
如果将一个树中的某个节点i的父节点设置为某个节点j，导致出现了环，那么显然从j沿着父节点的方向去递推（用并查集的find函数），最终一定会到达i节点（先把所有没有指定父节点的节点指向自己，即初始化fa[x] = x，这样find（j）就会在i节点处结束）**

**也就是说当i = find(j)的时候,如果把i的父节点设置为j，就会造成环的出现
抓住这一点，在环即将出现时，我们就可以把i的父节点改成指向统一的根节点，这样就用一个操作就把环消除了**

**优化：
由于最终我们要输出一个最少修改数量的数组，但是find函数的优化是建立在把大量节点直接挂到根节点下的这种操作上的，所以我建立了另一个数组icopy来让find函数得以优化**


```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cmath>
#include <queue>

using namespace std;

//并查集实现
//108ms

/**
*	思路:
*	所有可能的情况就两种,
*	1.正常的树
*	2.成环
*	我们要做的是,把环拆开成树,把所有树并在一起,要做到操作次数最少,那么当然是一个环在某一个地方拆开,指向另一个根节点,但是到底指向哪里暂时还不知道,所以让它先指向自己,称为假根节点,记录下这些假节点,之后再来处理它的去向
*	如果有多个根节点,选其中一个作为最终的根节点,其余的根节点和假节点都并在它的下面[操作次数=假根节点的数量 + 根节点的数量 - 1]
*	如果没有根节点,那么某一个假节点作为最终根节点[操作次数 = 假根节点数量 + 根节点数量(是0)]
*
*/

int n, changes = 0, root;

queue<int> fackRoot;

int fa[200005];//这个数组作为最后的输出结果
int facopy[200005];//这个数组作为最后的输出结果

void init() {
	for (int i = 1; i <= n; ++i) {
		facopy[i] = i;
	}
}

int find(int i) {//非递归实现
	int icopy = i;
	while (i != facopy[i]) {//找到根元素
		i = facopy[i];
	}

	while (icopy != facopy[icopy]) {
		icopy = facopy[icopy];//获取父节点
		facopy[icopy] = i;//挂到根节点下
	}

	return i;
}

int main(int argc, char const *argv[])
{
	scanf("%d", &n);

	init();

	for (int i = 1; i <= n; ++i) {
		scanf("%d", fa + i);

		if (fa[i] == i) {
			if (root) {
				changes++;//做出改变
				fa[i] = root;
			} else {
				root = i;
			}
			facopy[i] = root;
		} else {
			if (i == find(fa[i])) {//若出现环
				//加入到fackRoot
				fackRoot.push(i);
				// facopy[i] = i;//拆开环，作为假的根元素，暂时指向自己
				// 上面这一步操作不用写，因为之前对并查集执行过init()操作
			} else {
				facopy[i] = find(fa[i]);//直接挂在根节点
			}
		}
	}

	// 处理所有fackRoot
	changes += fackRoot.size();
	while (!fackRoot.empty()) {
		if (root) {//若之前确立了根元素
			fa[fackRoot.front()] = root;
			fackRoot.pop();
		} else {
			root = fackRoot.front();
		}
	}

	printf("%d\n", changes);

	printf("%d", fa[1]);

	for (int i = 2; i <= n; ++i) {
		printf(" %d", fa[i]);
	}

	printf("\n");
	return 0;
}

```