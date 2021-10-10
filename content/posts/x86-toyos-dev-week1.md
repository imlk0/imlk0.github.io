---
title: '自制x86玩具操作系统 week1'
date: 2019-05-01T00:00:00+08:00
id: 52
aliases:
  - /blog/52/
categories:
  - OSDev
tags:
  - 操作系统
  - DIY
---

## DAY 0x00
先装个翻译插件，装了半天找了个勉强能用的
然后考虑用git来做版本控制，方便和原版进行比较找出自己的修改，然后发现文字编码问题，于是乎捣鼓了个工具来批量转换文件编码（一大堆时间栽进去了）。

第0天用16进制编辑器编辑出一个image文件

## DAY 0x01

这张软盘共有1440KB大小，最高地址为0x168000-1

#### 文件描述
- tolset\z_tools\qemu目录中的MakeFile启动qemu-win.bat，本质上是设置环境并带参数启动qemu.exe
- tolset\z_tools\qemu\vgabios.bin : *BIOS (ia32) ROM Ext.* (19\*512)
- hellos0\helloos.img：*DOS/MBR boot sector*, code offset 0x4e+2, OEM-ID "HELLOIPL", root entries 224, sectors 2880 (volumes <=32 MB), sectors/FAT 9, sectors/track 18, sectors 2880 (volumes > 32 MB), serial number 0xffffffff, label: "HELLO-OS   ", FAT (12 bit), followed by FAT

#### 汇编
- 编译`.nas`文件用工具`nask`，`nask helloos.nas helloos.img`
- `DB`(define byte)用来以十六进制定义数据，一次一个Byte，多个之间逗号分割  
DB后还可以直接接字符串，字符串用`"包围"`起来，**编译器不在字符串后面自动加\0**
- `RESB`(reserve byte)用来定义空的字节个数，后面接数字，等价于`DB`后面加一堆`0x00`
- 数字字面量的表示形式和c语言里面一样0x开头为16进制
- `;`用于注释
- `DW`(define word),定义两个字节的数据
- `DD`(define double-word),定义4个字节的数据
- 数据部分支持先执行`加减乘除`运算再将结果写入
- `$`变量表示在`这个位置之前`已经写入的字节**个数**

#### 镜像文件格式
- 该软盘扇区大小为512字节，启动区在第一个扇区内，**计算机首先从最初的一个扇区内开始读盘**，启动区的末尾必须为`0x55AA`（无特别意义，仅仅作为启动区的标记）
- 软盘的一次读写以一个扇区为单位
- IPL是initial program loader的意思，启动程序加载器
- 操作系统和操作系统的加载程序在同一个地方的启动机制叫做bootstrap方式


## DAY 0x02

#### 汇编
- `ORG`指令指定程序装载到内存中的指定地址(这里一开始没看懂)
- `JMP`指令跳转到标签处
- 作者的nask汇编中指令遵循Intel汇编，第一个是目标操作数，第二个是源操作数

|寄存器名|全称|含义|
|------|----|---|
|AX|accumulator|累加寄存器|
|CX|counter|计数寄存器|
|DX|data|数据寄存器|
|BX|base|基址寄存器（例如用于指向数组起始位置）|
|SP|stack pointer|栈指针寄存器|
|BP|base pointer|基址指针寄存器（栈帧的基地址）|
|SI|source index|源变址寄存器|
|DI|destination index|目的变址寄存器|

|寄存器名|全称|含义|
|------|----|---|
|ES|extra segment|附加段寄存器|
|CS|code segment|代码段寄存器|
|SS|stack segment|（栈指针寄存器的）段寄存器|
|DS|data segment|数据段寄存器|
|FS|-|-|
|GS|-|-|

- `AH/AL`,`AX`,`EAX`,`RAX`分别为8，16，32，64位寄存器
- 标签`label`等价于地址，每个标签的地址是按照ORG指令加上偏移量计算得出的
- `[]`表示多一层寻址
- `BYTE`、`WORD`、`DWORD`这些汇编保留字和`[地址]`的组合，表示以给出的地址为低地址的一块数据
- `CMP`比较指令
- `JE`结果相等时的条件跳转
- `INT`是软件中断指令，可以调用BIOS里预设的函数，后面接一个数字表示调用不同的函数。  
调用前先将数据存到指定的寄存器
- `HLT`，(halt)让CPU停止动作，进入待机状态

##未完待续

先睡觉了，天气冷，折腾一天了。
- Linux 汇编器：对比 GAS 和 NASM：
[https://www.ibm.com/developerworks/cn/linux/l-gas-nasm.html](https://www.ibm.com/developerworks/cn/linux/l-gas-nasm.html)
- 各种编译器的区别 ASM: MASM, NASM, FASM?
[https://stackoverflow.com/questions/10179933/asm-masm-nasm-fasm/10180015](https://stackoverflow.com/questions/10179933/asm-masm-nasm-fasm/10180015)



## DAY 0x02 续

上网搜了一下，发现原来的info地址已经变成了[http://oswiki.osask.jp/](http://oswiki.osask.jp/)但是依然不能用，最后在google快照里面找到了踪迹`http://webcache.googleusercontent.com/search?q=cache:`后面接网页url即可
```
http://webcache.googleusercontent.com/search?q=cache:http://oswiki.osask.jp/?(AT)memorymap
```

helloos4中只取了helloos.nas的前半部分作为`ipl.nas`

#### 汇编
- nask编译时第三个参数为编译输出的列表文件，描述每个指令如何翻译成机器语言
- `ORG`指令编译不产生字节

#### Makefile
- `#`注释，`\`续行符号

```Makefile
目标: 依赖文件
	命令... \
```

- 第一个目标是默认目标
- 目标可以是一个文件，也可以是一个标签，称为伪目标


- `eding`能编辑img文件，将其它img文件放到指定的位置
- `ipl.bin`就是`helloos.img`的前0x00200个字节

启动时，首先执行BIOS，然后BIOS加载软盘的启动区，并在一些列操作之后跳转到启动区起始处的第一条`JMP`指令。
**启动区内容的装载地址为 0x00007c00-0x00007dff**，这不是操作系统规定的，也不是img镜像文件中指定的，镜像文件得遵循这一规定，这一过程由BIOS进行
day1和day2的最终镜像文件没有区别，在helloos2中作者故意将程序区不以汇编代码形式展示，是因为其中要用到标签的地址，而这个地址要结合`ORG`指令计算得出，到helloos3时才加入`ORG`指令
参考FAT12启动区的定义，软盘的信息描述在0x62处截止，作者填充了18个字节的内容，然后在偏移量为0x50处写入代码


### 参考
- FAT12文件系统之引导扇区结构：\
[http://xitongbangshou.com/?p=41](http://xitongbangshou.com/?p=41)




