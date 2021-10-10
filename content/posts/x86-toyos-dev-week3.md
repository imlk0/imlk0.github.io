---
title: '自制x86玩具操作系统 week3'
date: 2019-05-01T00:00:02+08:00
id: 54
aliases:
  - /blog/54/
categories:
  - OSDev
tags:
  - 操作系统
  - DIY
---

## DAY 0x06

#### Makefile
- make中可以使用一般规则（通配规则,依赖中:`%.cpp`,执行语句中:`$*.cpp`），但是普通规则比一般规则的优先级更高


#### 汇编
- GDTR寄存器有48位
- `PUSHAD`将通用寄存器(EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI)按顺序双字压栈，对应的恢复指令为`POPAD`，该指令的单字版本为`POPA`
- 普通C程序返回时需要调用`RET`，但是中断返回时需要调用`IRETD`
- C语言认为DS和ES和SS所指向的段都是一样的，因此在中断调用c程序前必须备份ES和DS的值并拷贝SS的值给DS、ES


#### 关于调试
可以在汇编中混入`INT 3`指令来断点调试,但是在中断向量表未准备好时,不能使用该方式
但是在使用bochsdbg时,可以在汇编中参入`MAGIC BREAKPOINT`,具体步骤是在bochs配置文件中加入`magic_break: enabled=1`,然后在汇编中加入`xchg bx,bx`,然后就能在该处断点

#### load_gdtr
`_load_gdtr`函数先取出第1个参数`limit`，地址为`ESP+4`,

```assembly
		MOV		AX,[ESP+4]		; limit
```
这是一个2字节指令,而因为之前分析过这个机器是小端模式,因此对于`0x0000ffff`,`WORD [ESP+4]`就是`0xffff`,把它放到了AX寄存器,然后
```assembly
		MOV		[ESP+6],AX
```
将`0xffff`放到了更高的两个byte上面,而`ESP+8`则是第二个参数`addr`的地址,这样一来,`limit`的低2字节和`addr`就连起来了,之后
```assembly
		LGDT	[ESP+6]
```
直接取了`ESP+6`为低位的6个byte的数据,放到`GDTR`寄存器,
这就是书上说的`GDTR`的6个字节的来源,**低2个字节是limit,高4字节是addr**

#### GDT的访问权属性
段号记录表中的项中的段属性中有一个`Gbit`位，
当该位为1时，记录的`limit`的单位不是byte而是页的大小，**一页是指4KB**

段的访问权属性`ar(access_right)`,由8位+4位扩展组成，高4位扩展为`GD00`,其含义为：
- G:Gbit，段长度单位是byte还是页数
- D:32位模式(1),16位程序模式(不可用于调用BIOS)(0)

低八位的部分组合的含义
```
00000000（0x00）：未使用的记录表（descriptor table）。
10010010（0x92）：系统专用，可读写的段。不可执行。
10011010（0x9a）：系统专用，可执行的段。可读不可写。
11110010（0xf2）：应用程序用，可读写的段。不可执行。
11111010（0xfa）：应用程序用，可执行的段。可读不可写。
```
x86的处理器通过ring0到ring4四个级别来进行访问控制
*系统模式(ring0)和应用模式(ring3)取决于运行中的程序代码所在的段的访问权限属性低8位是0x9a还是0xfa*


#### PIC(Programmable interrupt controller)可编程中断控制器
**用于将8个中断信号集合成一个中断信号**
每个PIC上面可以接收8个中断信号，主板上一共有两个PIC，一共有15个可用的中断信号，IRQ2被用于连接从PIC

> 中断号码表
```
IRQ0 	计时器
IRQ1 	键盘
IRQ2 	用于与从站级联
IRQ3 	串口（COM2）
IRQ4 	串口（COM1）
IRQ5 	主要用于ISA / PCI扩展设备
IRQ6 	FDC
IRQ7 	并行端口
IRQ8 	RTC
IRQ9 	主要用于ISA / PCI扩展设备
IRQ10 	主要用于ISA / PCI扩展设备
IRQ12 	鼠标
IRQ13 	FPU（？）
IRQ14 	ATA-0
IRQ15 	ATA-1
```
PIC内部有多个寄存器:
- IMR(interrupt mask register 中断屏蔽寄存器)，PIC的IMR寄存器每一位表示是否允许中断请求(1表示禁止)
- ICW(initial control word 初始化控制数据)共有四个，ICW1-ICW4，与PIC主板配线方式、中断信号的电气特性也有关系
	ICW3的值用于设定主从PIC。对于主PIC,第几号的IRQ与从PIC相连，就将那位置为1;而对于从PIC,接在主PIC的第几号(0 based)位置上,这个寄存器的值就设置为多少。
	ICW2的值用于设定中断号
- OCW(操作命令字)

> CPU有一根中断型号，由IF中断许可标志位标志标识是否接受外部中断（1表示接受，STL指令置1，CTL指令置0），而PIC可以对它导出的一共8个RIQ端口分别控制是否接受中断






## DAY 0x07

#### 中断处理
- 中断触发后，需要通知PIC已经处理完中断，这样PIC才会继续接受中断。
```cpp
io_out8(PIC0_OCW2, 0x61);// 0x61=0x60+0x01，表示已经处理IRQ1上的中断
```

> 键盘触发的中断会在键盘按下和松开的时候都触发一次
- 似乎`io_stihlt()`由于CPU规范的原因能保持原子性
> 根据CPU的规范，机器语言的STI指令之后，如果紧跟着HLT指令，那么就暂不受理这两条指令之间的中断，而要等到HLT指令之后才受理
- 无缓冲的消息机制的键盘按键中断处理在中断密集时，会出现后续的中断来不及被处理（来不及关闭中断开关）的问题，解决办法是使用缓冲区
但是我实际操作调试中断时并没有看到传说中的被吞掉的E0数，只看到按下时的`0x1D`和松开时的`0x9D`
- KBC(keyboard controller)键盘控制器，控制键盘和鼠标

#### 关于C++
- 为了方便显示，我在Cursor类里面加了个单例模式的static函数，但是C++实现函数内的static变量（局部静态变量）时，为了确保在多线程状态下只初始化一次，在编译时增加了同步锁，但是由于同步锁的实现函数在libstdc++内，而我们是没有链接这个库的，因此使用编译时的`-fno-threadsafe-statics`选项，禁用该功能。
> C++静态局部变量对于基本类型的常量初始化时，采取直接定义一个隐藏的全局变量的方法，例如对于函数：
```cpp
int ofEndLine(){
	static int i = 1;
	i++;
	return i;
}
```
其汇编为
![用常量初始化静态局部变量](/images/blog/os/1.png)
而对于需要调用函数来进行初始化的静态局部变量，
```cpp
int ofEndLine() {
	static int i = getValue();
	i++;
	return i;
}
```
则是
![用函数初始化静态局部变量](/images/blog/os/0.png)
这其中就用到了`___cxa_guard_acquire`和`___cxa_guard_release`。



## DAY 0x08

- 鼠标的数据除第一次发送的是0xfa(表示启动鼠标后的ACK)以外，其它数据按照3个字节一组发送。
> 每组中,第一个字节的高4位是对移动有反应的部分(在[0,3]的范围内),低4位是对点击有反应的部分(在[8,f]的范围内)
|	|7|6|5		|4		|3|2	|1			|0		|
|---|-|-|-------|-------|-|-----|-----------|-------|
|0	|0|0|上移	|右移	|1|		|			| 		|
|1	|0|0|下移	|左移	|1|右键	|中键(按下)	|左键	|
> 第二个字节和左右移动有关
> 第三个字节和上下移动有关
> 鼠标与屏幕的y方向正好相反,因此y使用前应该加负号
- 状态和控制寄存器
	`EFLAGS`、`EIP`、`CR0`、`CR1`、`CR2`、`CR3`
	|寄存器	|作用|
	|-----	|---|
	|EFLAGS	|状态寄存器组|
	|EIP	|存储下一条指令的地址|
	|CR0|启用保护模式PE（分段机制）（Protection Enable）标志、分页PG（Paging）标志、等|
	|CR1|未定义|
	|CR2|页故障线性地址寄存器，保存最后一次出现页故障的全32位线性地址|
	|CR3|页目录基地址寄存器PDBR（Page-Directory Base address Register），保存页目录表的物理地址，页目录表总是放在以4K字节为单位的存储器边界上|
- 保护模式状态切换之后，需要立即使用JMP指令刷新处理器执行管道
- 在保护模式下，采用段表的方式，段寄存器中存放段表中目标项的偏移量（单位为Byte）
	例如：
	```assembly
		MOV		AX,1*8			; 段寄存器DS为1*8，表示段表中的从0开始数起的第1个项
		MOV		DS,AX
	```

#### asmhead.nas 之后所做的事情
- PIC关闭一切中断
- 设定A20GATE，使CPU能够访问1MB以上的存储器
- 指定临时段表
- 切换到保护模式PE，开启分页PG
- 刷新流水线
- 初始化除CS外的段寄存器
- 拷贝`bootpack.hrm`到`0x00280000` `(512KB)`
- 拷贝`ipl`启动扇区到`0x00100000` `(512B)`
- 拷贝磁盘上之前加载到内存区的除了启动区的部分到`0x00100200`
- (可能进行)拷贝`bootpack.hrm`的某块区域到`bootpack.hrm`指定的栈地址中
- 初始化栈地址为`bootpack.hrm`指定的栈地址
- 设置`CS`寄存器的值的同时`JMP`到`HariMain`函数执行



#### 汇编
- `IMUL`，有符号整数乘法
- `SHL`，逻辑左移，`SHR`，逻辑右移
- `ALIGNB`表示填充0直到地址能被操作数整除



#### 引用
- PIC 8259A
[http://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?(PIC)8259A](https://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?(PIC)8259A)
- 兼容PS/2键盘控制器
[http://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?(AT)keyboard](https://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?(AT)keyboard)
- 局部静态变量是如何做到只初始化一次的?
[www.voidcn.com/article/p-wdezklav-bms.html](www.voidcn.com/article/p-wdezklav-bms.html)
- x86的控制寄存器CR0,CR1,CR2,CR3
[https://www.cnblogs.com/liubiyonge/p/9350494.html](https://www.cnblogs.com/liubiyonge/p/9350494.html)
