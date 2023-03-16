---
title: 'HYSBZ 1216: [HNOI2003]操作系统'
id: 19
aliases:
  - /blog/19/
categories:
  - Algorithm
date: 2018-02-07T23:27:09+08:00
tags:
  - HYSBZ
---

[题目链接](http://www.lydsy.com/JudgeOnline/problem.php?id=1216)

```
1216: [HNOI2003]操作系统
Time Limit: 10 Sec  Memory Limit: 162 MB
Submit: 1045  Solved: 565
[Submit][Status][Discuss]
Description

写一个程序来模拟操作系统的进程调度。假设该系统只有一个CPU，每一个进程的到达时间，执行时间和运行优先级都是已知的。其中运行优先级用自然数表示，数字越大，则优先级越高。如果一个进程到达的时候CPU是空闲的，则它会一直占用CPU直到该进程结束。除非在这个过程中，有一个比它优先级高的进程要运行。在这种情况下，这个新的（优先级更高的）进程会占用CPU，而老的只有等待。如果一个进程到达时，CPU正在处理一个比它优先级高或优先级相同的进程，则这个（新到达的）进程必须等待。一旦CPU空闲，如果此时有进程在等待，则选择优先级最高的先运行。如果有多个优先级最高的进程，则选择到达时间最早的。
Input

输入文件包含若干行，每一行有四个自然数（均不超过108），分别是进程号，到达时间，执行时间和优先级。不同进程有不同的编号，不会有两个相同优先级的进程同时到达。输入数据已经按到达时间从小到大排序。输入数据保证在任何时候，等待队列中的进程不超过15000个。
Output

按照进程结束的时间输出每个进程的进程号和结束时间
Sample Input
1 1 5 3

2 10 5 1

3 12 7 2

4 20 2 3

5 21 9 4

6 22 2 4

7 23 5 2

8 24 2 4
Sample Output
1 6

3 19

5 30

6 32

8 34

4 35

7 40

2 42
```

这题利用了优先队列

```
#include <iostream>
#include <cstdio>
#include <cstring>
#include <queue>

#define iinf 0x7FFFFFFF

// AC
// 优先队列

using namespace std;

int proCount;

struct Pro {
	int id;
	int comeTime;
	int runTime;
	int priority;
	Pro(int a, int b, int c, int d): id(a), comeTime(b), runTime(c), priority(d) {}
};

struct cmp {//判断“一个元素是否小于另一个元素”的结构体
// 重载operator ()必须是某个类的成员函数。
// 当某个类重载了()方法，这个类就可以成为函数对象。
	bool operator() (Pro*& p0, Pro*& p1) const {//关于这里的参数最前是否需要加const关键字，我的应对策略是：先试着加上，如果有错的话，编译器会回答找不到对应的方法，比如，加了const提示 ： error: no match for call to ‘(cmp) (Pro*&, Pro*&)’，可知这里不用加const
		if (p0->priority == p1->priority) {//若优先级相同，则更早来的在前面（优先队列中最前的元素，即top()，是比较之后值最大的那个元素，要让时间更前的元素排得越前，则它在这个自定义比较函数里面的“值”越大越好，即：优先级相同的两个元素，时间更前的元素反而更大）
			return p0->comeTime > p1->comeTime;//若第一个参数指向的元素来到时间比第二个元素的早，则表达式返回 false，代表第一个参数指向的元素大于第二个元素，排的更前。
		} else {
			return p0->priority < p1->priority;//若优先级不同，则优先级高的在前面
		}
	}
};

/**
*	为什么我不直接在Pro结构体内部重载 < 操作符，因为我这个queue存的是指针变量，并不是实际的元素，重载Pro结构体的 < 操作符不会有作用，因为这时候queue里面比较的是Pro*类型的元素，我们要想办法为Pro*类型的元素适配比较函数
*	所以我写了上面那个比较函数，后来看了别人的代码发现，上面这个自定义的比较函数其实可以不用这么麻烦
*	我们要想办法让 < 操作符支持 Pro* 类型和 Pro* 类型之间的比较，所以我们可以在全局方范围内重载 < 操作符
*	例如：
*	
*	bool operator < (Pro p0, Pro*& p1) {
*		if (p0->priority == p1->priority) {
*			return p0->comeTime > p1->comeTime;
*		} else {
*			return p0->priority < p1->priority;
*		}
*	}
*	同时下面的waitQu改成
*	priority_queue <Pro*> waitQu;
*	可是，编译报错
*	 error: ‘bool operator<(Pro*&, Pro*&)’ must have an argument of class or enumerated type
*	 bool operator < (Pro*& p0, Pro*& p1) {
*	                                    ^
*	原来c++有些操作符在某些情况下是不能重载的，比如对两个指针的比较的小于号操作符，这个操作符已经有具体实现了，我们不能重载它，否则那些库里面用到用<比较指针的操作都变成了我们自定义的操作了，岂不是乱了套
*/

queue<Pro*> allPro;

priority_queue <Pro*, vector<Pro*>, cmp> waitQu; //存放排队等候中的进程
//									^这里在模板中传入比较函数的类型，相当于自己实现一个 < 函数

int main(int argc, char const *argv[])
{
	int a, b, c, d;
	Pro* t;
	while (~scanf("%d%d%d%d", &a, &b, &c, &d)) {
		t = new Pro(a, b, c, d);//这里是手动在堆上申请内存，让queue和priority_queue维护指针，实际上不用这样，可以直接在栈上建立一个Pro元素，queue和priority_queue会进行拷贝操作，在堆上形成一份原来栈内存上的元素的拷贝
		allPro.push(t);//先读取放到allPro这个队列中
	}

	int nowTime = 0;
	int stepTime;//一次步进多长时间

	for (; (!waitQu.empty()) || (!allPro.empty());) {//当等待队列waitQu和allPro队列都为空时就退出

		stepTime = iinf;

		if (!waitQu.empty()) { //若等待队列中还有元素
			stepTime = min(stepTime, waitQu.top()->runTime);
		}

		if (!allPro.empty()) {//若未加入的任务队列中还有元素
			stepTime = min(stepTime, allPro.front()->comeTime - nowTime);
		}
		//至此步进时长确定完成

		nowTime += stepTime;

		if (!waitQu.empty()) {
			//每次处理等待队列中的第一个元素
			waitQu.top()->runTime -= stepTime;//等待队列中的第一个元素的剩余运行时间减去步进时间
			if (waitQu.top()->runTime == 0) {//若任务执行完毕
				printf("%d %d\n", waitQu.top()->id, nowTime);
				delete waitQu.top();//记得释放内存
				waitQu.pop();
			}
		}

		if (!allPro.empty()) {
			if (nowTime == allPro.front()->comeTime) {//若第一个未加入的任务时机已到，则加入任务到等待队列中
				waitQu.push(allPro.front());
				allPro.pop();
			}
		}
	}

	return 0;
}
```