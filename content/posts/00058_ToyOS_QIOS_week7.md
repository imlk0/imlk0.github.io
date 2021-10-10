---
title: '自制玩具操作系统--week7'
date: 2019-05-01T00:00:06+08:00
id: 58
aliases:
  - /blog/58/
categories:
  - OS
tags:
  - 操作系统
  - 笔记
---

## DAY 0x12

#### 让新进程执行对象的成员函数
今天回看之前的内容，发现命令行窗口那一块比较乱，于是乎建了一个`Console`类，把和控制台有关的比如图层、`Fifo`队列等打包起来，然后把进程的执行函数`console_task`改成无参的成员函数，但是要知道它其实是隐式传入了一个`this`指针，所以在设置`eip`的时候可不是仅仅传入成员函数指针那么容易。

c++的编译器在调用函数时传入this指针时的方法称为`__thiscall`调用约定，有两种实现，一种是通过`ecx`寄存器传参，另一种是压栈为第一个参数传参。
要确定当前编译器使用的是哪种`__thiscall`调用约定，直接拿个例子编译一下看看就好了。

先拿了一个直接用对象去调用成员函数的例子来观察，
![9.png](/images/blog/os/9.png)
可以看到，普通成员函数其实只是一个一般的函数，但是在调用前将这个对象的指针赋值给了`ecx`寄存器，这个`ecx`就是this指针啦。

```cpp
	task_cons->tss.esp = memman_alloc_4k(memman, 64 * 1024) + 64 * 1024 - 4; // 没有用栈传递的参数，这里只要预留压栈ebx所需的空间即可
	task_cons->tss.ecx = (int)this; // this指针通过ecx传递
	task_cons->tss.eip = (int) (void*)&console_task; // 指定成员函数
	...
	// 可以通过this指针访问成员变量，这里不用费心思从栈上传一堆参数了
	// *((int *) (task_cons->tss.esp + 4)) = (int)canvas_cons;

```

#### 支持美式键盘
之前做的时候没有注意到作者的键盘映射居然不是美式的，怪不得有些按键效果不太对
从网上找到一份类似的键盘映射表换一下就好了

https://github.com/gdevic/linice/blob/829862cb11e4f062d561c854536fa338985672bb/linsym/Keymaps.c


## DAY 0x13

#### 改用c++编译器后患无穷
之前提到我现在的代码用的是c++来编写，编译器用的mingw64里的c++，在做`type`命令时，遇到了一个玄学bug。

其中一段代码如下
```cpp
		int x;
		for (x = 0; x < 224; x++) {// 遍历所有文件
			if (sys::finfo[x].name[0] == 0x00) {// 后面没有任何文件了
				break;
			}
			// 判断文件名称是否符合
			if ((sys::finfo[x].type & 0x18) == 0) {
				bool flag = true;
				for (int y = 0; y < 11; ++y) {// 遍历文件名中的char
					if (sys::finfo[x].name[y] != file_name[y]) {// 和参数中的文件名比较
						LOGD("%d nq %d at %d", (int)sys::finfo[x].name[y], (int)file_name[y], y);
						LOGD("f0:%se",sys::finfo[x].name);
						LOGD("f1:%se",file_name);

						flag = false;
						break;
					}
				}
				if (flag) {
					break;
				}
			}
		}
```
看一下运行结果
![10.png](/images/blog/os/10.png)
注意到log里倒数第三行，`32 nq 0 at 13`，
首先说明一下，这里比较的是文件名的11个字符（文件名8byte+扩展名3byte，处理时跳过了小数点）。
它看起来比较时匹配到了MakeFile这个文件，但是在文件名索引为13(即y=13)的地方发生不匹配。

what happened？ y怎么可能等于13？？？？？

上面for循环判断不是写着`y < 11`吗，程序疯了吧。
看一下`FILEINFO`结构体的定义
```cpp
struct FILEINFO {
	unsigned char name[8], ext[3], type;
	char reserve[10];
	unsigned short time, date, clustno;// clustno 表示起始扇区
	unsigned int size;
};
```
看起来作者是用了一个结构体的特性，`name`（文件名）和`ext`（后缀）的内存是连续放置的，所以作者打算一次性比较11个字符来匹配文件名和后缀。
但是为什么这里y能跑到13呢？难道是内存不够了篡改了y的值？但是输出那里没法解释啊，输出的y是13，总不会是输出函数有问题吧。

为了探寻真相，来看看汇编
![11.png](/images/blog/os/11.png)
由于有字符串，这段代码并不难找到，上方是循环体，`loc_494`是for循环的判断，看起来`eax`就是那个`y`变量，奇怪的是，在`loc_494`那里让`y`加一然后就`jmp`走继续执行循环体了，没看到和循环边界`11`比较的`cmp`部分，吃惊。
开始猜测是傻逼编译器又给我优化了，把for循环里`y`的上界改成`8`编译试试看。
![12.png](/images/blog/os/12.png)
只见原来的`jmp`变成了`jnz`，跳转指令之前出现了一条`cmp`指令，傻逼编译器石锤了！

解决办法，把`sys::finfo[x].name`赋值给一个临时变量，这样傻逼编译器就看不到它的长度，也就不会优化了，骗过了编译器
```cpp
unsigned char* aim_name = (unsigned char*)sys::finfo[x].name;
```
不过这个傻逼编译器为什么要把我这个给优化掉呢？？

#### hlt.hrb
`hlt.hrb`里面本质上是编译好的机器指令，
那么`bootpack.hrb`应该也是机器指令，那么`OBJ2BIM`应该就是链接器，`haribote.sys`就是`asmhead.bin`和`bootpack.hrb`这两个机器指令文件组合起来的，所以也是编译好的机器指令。


## DAY 0x14

最后作者传入字符串地址最后什么都没有输出，先看了一下后一天的内容，发现作者又是通过在别处内存处存储临时的值来实现的，感觉这样很别扭，于是想能否获取到要打印的字符串的地址然后把地址传过去，作者说遇到的问题是分段的问题，尝试了一番，发现可以把`CS`段寄存器的值先存到别的寄存器，然后在`hrb_api`里面恢复出来传到`cons_putstr`里面，再在`naskfunc`里面写一个依据段寄存器和偏移地址取数据的函数，让`cons_putstr`去调用取字符。
```cpp
void cons_putstr(Console *console, int ds, int ecx) {
	char ch;
	while (ch = get_data(ds, ecx)) {
		console->putfont8(ch);
		ecx++;
	}
}
```
```assembly
_get_data:		; int get_data(int ds, int ecx);
		MOV		ECX,[ESP+8]
		MOV		EAX,[ESP+4]
		MOV		EDX,DS
		MOV		DS,EAX
		MOV		EAX,0
		MOV		AL,[DS:ECX]
		MOV		DS,EDX
		RET
```
