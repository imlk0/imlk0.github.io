---
title: '自制玩具操作系统--week2'
date: 2019-05-01 00:00:01
id: 53
categories:
  - [OS]
tags:
  - [操作系统]
  - [笔记]
---

## DAY 0x03

#### Makefile
- 命令块中`-del + 文件`表示让make中删除该文件

#### 汇编
- `INT 0x13`中断表示操作磁盘
|参数|取值和含义|
|--|--------------|
|AH|`0x00`复位磁盘,`0x02`读盘,`0x3`写盘,`0x4`校验,`0xc`寻道|
|AL|要处理的扇区数目(最少为1)|
|CH|表示柱面号&0xff (从0开始)|
|DH|磁头号(从0开始)|
|CL|扇区号(0-5位)|(柱面号&0300)>>2 (从1开始)|00000011 00000000
|DL|驱动器号(从0开始)|
|ES:BX|ES\*16+BX缓冲区地址(ES左移4位,即十六进制后面追加一个0)|
读盘成功后CF置0,失败则置1

例如
```nasm
		MOV		AX,0x0820
		MOV		ES,AX			; 缓冲区段地址
		MOV		CH,0			; 柱面号为0
		MOV		DH,0			; 磁头号0
		MOV		CL,2			; 扇区号2

		MOV		AH,0x02			; AH=0x02 : 从磁盘读入
		MOV		AL,1			; 1读取一个扇区
		MOV		BX,0			; 缓冲区地址
		MOV		DL,0x00			; 0号驱动器
		INT		0x13			; 磁盘BIOS调用
		JC		error
```
该1.44Md的3.5寸软盘共有**80个柱面(cylinder)(0-79),2个磁头(0-1),18个扇区(1-18)**
启动区位于C0-H0-S1,扇区序号按`扇区→磁头→柱面`的顺序进位

- `JC`(Jump if Carry)(CF)条件跳转,产生进位时跳转
- `JNC`
- `JAE`(Jump if above or equal)大于等于时跳转
- `JBE`(Jump if below or equal)大于等于时跳转
- `JB`
- `EQU`是queal的缩写,`CYLS EQU 10`表示定义符号`CYLS`为数字10



#### 内存区域(x86)
低地址区域
```txt
|-------------------------------------------------------|0x00000000
|	1 KiB 	RAM - partially unusable (see above) 		|
|	Real Mode IVT (Interrupt Vector Table)			 	|0x000003FF
|-------------------------------------------------------|0x00000400
|	256 bytes 	RAM - partially unusable (see above)	|
|	BDA (BIOS data area)								|0x000004FF
|-------------------------------------------------------|0x00000500
|	almost 30 KiB 	RAM (guaranteed free for use)		|
|	Conventional memory									|0x00007BFF
|-------------------------------------------------------|0x00007C00 ←
|	512 bytes 	RAM - partially unusable (see above)	|
|	Your OS BootSector									|0x00007DFF
|-------------------------------------------------------|0x00007E00
|	480.5 KiB 	RAM (guaranteed free for use)			|
|	Conventional memory									|0x0007FFFF
|-------------------------------------------------------|0x00080000
|	128 KiB 	RAM - partially unusable (see above)	|
|	EBDA (Extended BIOS Data Area)						|0x0009FFFF
|-------------------------------------------------------|0x000A0000
|	384 KiB 	various (unusable)						|
|	Video memory, ROM Area								|0x000FFFFF
|-------------------------------------------------------|
```


### 参考
- Memory Map (x86):\
[https://wiki.osdev.org/Memory_Map_(x86)](https://wiki.osdev.org/Memory_Map_(x86))

关于作者开发的`edimg.exe`工具
```Makefile
edimg imgin:../z_tools/fdimg0at.tek \ #读取映像文件
		wbinimg src:ipl.bin len:512 from:0 to:0 \ #将指定文件的内容写入映像的指定位置，一般用于写入引导扇区
		copy from:haribote.sys to:@: \ #将文件写入磁盘映像中或从中取出文件,@:表示盘符，类似于C:和D:等
		imgout:haribote.img #输出文件名
```

`ipl.nas`启动后从C0-H0-S2开始加载，加载到0x08200地址处，略过了启动区。
`haribote.nas`开头设置`ORG 0xc200`，其中`0xc200=0x08200-0x00200+0x04200`,意味着这段程序将被加载到`0xc200`这个地址
作者书中说整个磁盘上的内容被加载到`0x08000`号地址，但实际上代码只加载了第二扇区开始的内容到`0x08000`，调试查看`0x08000-0x08200`并没有找到启动区的数据，发现该系统采用小端字节序，不知道和我用的是bochs还是qemu也没有关系
- `0x04200`，查阅资料得知这是FAT12文件系统的文件数据区（第33扇区）,所以用`edimg`进行`copy`操作到磁盘中的第一个文件的地址偏移量就是`0x04200`



### 参考
- edimg工具的使用:\
[http://webcache.googleusercontent.com/search?q=cache:hex7N0E90QkJ:hrb.osask.jp/wiki/%3Ftools/edimg+&cd=2&hl=zh-CN&ct=clnk](http://webcache.googleusercontent.com/search?q=cache:hex7N0E90QkJ:hrb.osask.jp/wiki/%3Ftools/edimg+&cd=2&hl=zh-CN&ct=clnk)
- 【文件系统】FAT12文件系统简介:\
[https://blog.csdn.net/xhyzjiji/article/details/49027013](https://blog.csdn.net/xhyzjiji/article/details/49027013)


启动程序加载器完成磁盘数据的加载以后，跳转到第一个文件的位置开始执行，确认无误以后`make run`但是究竟程序有没有出错呢，屏幕一片黑啥也看不出，于是在切换显卡模式以后，往屏幕上输出一段信息确定启动没有问题。

然后是加了一堆预定义的地址，记录一堆数据，其中有一个图像缓冲区的初始地址`0xa0000`，于是尝试直接debug往这个地址以及后面的那块区域里面写东西，但是并没有像预想的那样在屏幕上出现图案。emmm先留着。

查看网页发现`0xa0000到0xaffff`是VRAM的空间，一个像素点是一个字节，分辨率是320\*200，试试循环画点？

尝试了如下代码，
```
		MOV		DX,0xf0
		MOV		CX,0
		MOV		BX,0
		MOV		AX,0xa000
		MOV		ES,AX
		JMP		write_VRAM

write_VRAM:
		MOV		BX,CX
		ADD		CX,1
		CMP		CX,320*200
		MOV		[ES:BX],DX
		JBE		write_VRAM
```
结果整个屏幕果然呈现了棕绿色，吧DX改为0x0f，结果屏幕变成了全白色
最后选定了`0x08`，深灰色

证实了，确实能直接在显示内存区域直接写数据然后显示出来


接下来在`asmhead.nas`里加上一堆汇编代码，然后最终调用了`bootpack.c`的`HariMain()`，然后用汇编编写了一个输出模式为`WCOFF`的`naskfunc.nas`文件，其中编写了执行HLT指令的函数`io_hlt()`，然后编译成目标文件让`bootpack.c`链接,暴露的函数名称要声明为`GLOBAL`。
在

- `bim`是作者设计的一种文件格式，意思是`binary image`

将目标文件用作者的工具链接起来以后就会得到bim文件
- `hrb`是机器指令组成的文件
作者将c文件编译(cc1)，转为nas(gas2nask)，汇编编译(nask)得到目标文件，目标文件链接(obj2bim)得到bim文件，bim文件转换为hrb文件(bim2hrb)，然后asmhead.nas汇编(nask)出来的文件和这个hrb文件拼接起来就得到了最终的机器指令文件(haribote.sys)，由ipl加载并执行
（真麻烦）

总之这样超长的第三天过去了，还剩下asmhead里面加的100行代码作者没有解释
不如先试着看看吧，能看多少是多少
#### 汇编
- `OUT`指令和`IN`指令是对外设的操作的读写指令(访问系统的io空间)
	`OUT 0x21,AL`表示将AL寄存器的值写入0x21端口
- `CLI`指令禁止中断发生，`STL`指令允许中断发生
- `CALL`命令在跳转前将下一条指令的地址（段和偏移）压入栈中，执行`RET`时则从栈中取出地址回到`CALL`的下一跳地址处执行



## DAY 0x04

因为自带的cc1不支持最高只支持c99，用着很不爽，改成了电脑上装的gcc输出汇编指令，发现也能运行，只是gas2nask的时候程序状态值为1，但是不影响运行，修改makefile在该条指令前加上`-`就能避免整个make进程的中断

#### 汇编
- 编写C语言函数的的汇编函数体时，寄存器要慎用，自由读写的只有`EAX,ECX,EDX`
这三个，其他的只能使用其值而不能改变
- `[INSTRSET "i486p"]`指令(instr set,判断指令集)标识这个汇编程序是提供给486使用的（EAX等寄存器名不能16位的8086中使用，自386开始的cpu都是32位的）

#### Makefile
- 命令前加上`-`表示即使这条命令即使出错也继续执行

作者第四天一开始在c程序里面进行了绘制操作，但是我在第三天的时候已经用汇编指令对图像内存缓存地址区域进行了写值，因此，这里验证了`write_mem8`以后注释这一段了
在第三天的时候我也用汇编的形式在`asmhead.nas`里做了作者第四天做的第二件事情，写入条纹图案，只不过我写入的条纹时写入的是`i`而不是`i&0x0f`，不过也看到了一些奇怪的条纹

之后作者长篇叙述了指针的概念及其实现,这些已经懂了的知识就草草看完进入第四天的第6小节了

#### VGA8位色号
作者定义的调色板:
```
 0:#000000:黑	 6:#00ffff:浅亮蓝	12:#000084:暗蓝
 1:#ff0000:亮红	 7:#ffffff:白		13:#840084:暗紫
 2:#00ff00:亮绿	 8:#c6c6c6:亮灰		14:#008484:浅暗蓝
 3:#ffff00:亮黄	 9:#840000:暗红		15:#848484:暗灰
 4:#0000ff:亮藍	10:#008400:暗绿
 5:#ff00ff:亮紫	11:#848400:暗黄
```

#### VGA/EGA调色板技术

调色板是当初为了节约宝贵的内存空间而设计的一种解决方案，屏幕上最多可以显示16种颜色，在EGA的16个颜色寄存器存储颜色的。每个颜色存储器有`3*6=18`位，其中R、G、B各用6位表示，即R、G、B各有64种取值，从0到63代表颜色的程度，所以一种颜色用18位表示。这样机器能够显示的颜色总共有`64*64*64=256k`种，但是同一时刻在屏幕上显示的颜色只有16种，图像缓存区域中每个像素点只需用一个字节（实际上是0-15的值）来表示这16种颜色的索引号。


- c语言中,函数内定义的static类型的数据会被存放到栈外的一块单独的内存区域,如果指定了初始值,相当于`DB 初始数据`



`EFLAGS`寄存器(32位，由FLAGS扩展而来)，`FLAGS`的各个位含义
```
-------------------------------------------------
|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|  |NT| IOPL|OF|DF|IF|TF|SF|ZF|  |AF|  |PF|  |CF|
-------------------------------------------------
```
中断标志位在第9位

#### 汇编
- `PUSHFD`(push flags double-word)，将32位的EFLAGS压栈，对应的还有`POPFD`  
	因为`EFLAGS`和其他寄存器，比如`EAX`之间没有直接的汇编指令相互传送，因而需要用栈作为中介
- 根据C语言的规约，执行`RET`语句时，EAX寄存器中的值被看作是函数的返回值


### 参考
- 视频图形阵列-视频DA转换器
[http://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?VGA](http://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?VGA)


## DAY 0x05

由hankaku.txt生成的obj文件中，`.data`段存的是连续的字符数据，该obj文件导出了一个符号`_hankaku`
要使用该外部obj导出的符号，只要在c文件里用`extern char hankaku[4096]`即可 

第五天的实验开始出现了问题，因为之前由于忍受不了只允许使用c99标准，我改成了用gcc -S 输出代码，但是现在似乎问题更大了，gcc输出的汇编中包含一个叫`.section .rdata`的段，这个段不能被`gas2nask`识别，而函数调用参数中的字符串字面量就在这个段里存着
比如
```
putfonts8_asc(vram, xsize, ysize, 0, 0, COL8_FFFFFF, "test it!");
```
这条里面的`"test it!"`就在这个段里，被gas2nask忽略掉了以后，导致生成的nas文件里头缺失了这部分内容，nask编译出错。
上网意外找到了作者的github，clone下来编译不过关，缺少个文件，遂放弃。
有意外找到OSASK项目的项目中文首页，从中下载了2010年的版本，没想到这个作者依然没有注意到这个bug，我绝望了，删光了下载的东西，决心不用nask了，另外想办法整一下

回忆编译流程，发现bootpack.c最终是为了生成.obj目标文件，而这个作者偏偏要先生成.gas，再生成.nas，再用他那个nask编译成.obj，其实这其中的步骤完全就可以省略嘛，我之前就用了gcc，现在，直接可以`gcc -c`生成目标文件，于是乎改写Makefile，直接通过编译！（坑爹的作者）

既然改了这么多，代码也越来越乱，干脆一改到底，就用c++，反正c++也是兼容c的问题不大。

但是用c++编译，链接时出现问题
```
Warning : can't link _HariMain
```
原因是c++编译的名字修饰规则和c的不匹配，入口函数被编译成了`__Z8HariMainv`，这下我大概明白它的原理了，我们在写的`bootpack.cpp`是要被作为类库一样被链接的，而另外一边是已经写好了的，所以只能让我们这边做妥协，到解决办法是定义处套上`extern "C"`就好了

在引入了c++的基础上，我新建了几个文件，还增加了Cursor类和Mouse类，Cursor对象相当于一个隐形的光标，封装的函数，可以方便地进行定位，比如，下一格，换行等操作，这样代码也更加清晰。

#### 分段

- 32位模式，`DS:EBX`不再表示DS\*16+EBX，而是`EBX+(DS所表示的段的起始地址)`，而且缺省时也默认使用DS这个段寄存器。

##### 段的有关信息（CPU用8个字节，即64位的数据来表示这些信息）
- 段的大小(存储时存储段的大小-1后的值，以节省空间，limit)
- 段的起始地址(base)
- 段的管理属性（禁止写入，禁止执行，系统专用等，ar）


- 段寄存器只有16位，即使是在32位模式下也是如此
- 段寄存器的底三位由于设计原因不能使用，因此只剩下13位，只能表示8192个段

##### GDT 全局段号记录表(global segment descriptor table)
- 和调色板一样的思想，8192个段
- GDT存在于内存中，用来存储段的有关信息，表中每一项需要8个字节（8192\*8个字节=64KB）
- `GDTR`寄存器存储了这个表的起始位置和这个表的长度（字节数-1）

##### IDT 中断记录表(interrupt descriptor table)
- IDT记录了0-255的中断号吗和调用函数的对应关系，表中的每一项也是8个字节

数据的组织形式应该是和机器是小端模式有关系，因为GDT的数据结构中base字段的低24位被储存到16位的base_low和base_mid的低八位中了，但是base剩下的最高8位为什么被存储到与前面两个字段不相邻的base_high字段我就不清楚了。

