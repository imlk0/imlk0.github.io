---
title: '自制玩具操作系统--week10'
date: 2019-05-01T00:00:09+08:00
id: 62
aliases:
  - /blog/62/
categories:
  - OSDev
tags:
  - 操作系统
  - DIY
---

## DAY 0x1B

回顾`TSS`结构体，其中有一`CR3`字段，该字段在task切换的时候会自动赋值给`CR3`寄存器，我们可以在这里给用户程序设置额外的页目录地址（物理地址），

首先需要分配一张页表

按照内存中的结构来构造页目录结构体和页表结构体
```cpp
struct PAGE_DE {
	unsigned int entrys[PAGE_DE_ENTRY_NUM];
};

PAGE_DE* alloc_page_de(MEMMAN* memman) {
	PAGE_DE* p = (PAGE_DE*)memman_alloc_4k(memman, sizeof(PAGE_DE));
	utils::memset(p, 0, sizeof(PAGE_DE));
	return p;
}
```

获得页表以后，可以分配一定的内存区域来存放用户程序数据，作者在运行用户程序时，采用新增一项段表的方法将逻辑地址映射到物理地址，但是我们这里依然绕过段表，直接用页表映射到物理地址。
所以，我们将从`0x00000000`开始的线性地址区域映射到我们刚刚分配的用户程序区域的物理地址：
```cpp
map_page_addr2addr(sys::memman, pagede, 0, segsiz, (unsigned int)q - LADDR_K_BASE, 7, 7); // user access | write | present
```
注意flag设置为“用户态可访问、可写、该页存在”

```cpp

// 映射地址到页目录，要求start_laddr和start_paddr低12位相同
void map_page_addr2addr(MEMMAN* memman, PAGE_DE* pagede, unsigned int start_laddr, unsigned int size,
                        unsigned int start_paddr, unsigned int demode, unsigned int tamode) {

	unsigned int end_laddr = start_laddr + size;
	end_laddr = (end_laddr - 1 + 0x1000) / 0x1000  * 0x1000;// 4k向上对齐
	start_laddr = start_laddr / 0x1000 * 0x1000;// 4k向下对齐
	start_paddr = start_paddr / 0x1000 * 0x1000;// 4k向下对齐

	unsigned int start_entry = start_laddr >> 22;
	unsigned int end_entry = ((end_laddr - 1 + 0x400000) / 0x400000  * 0x400000) >> 22;// 4MB对齐
	unsigned int sub_start_laddr = start_laddr;
	unsigned int sub_end_laddr = 0;
	unsigned int sub_start_paddr = start_paddr;
	unsigned int sub_size = 0;

	for (int i = start_entry; i < end_entry && i < PAGE_DE_ENTRY_NUM; ++i) {
		PAGE_TA* pta = (PAGE_TA*)((pagede->entrys[i]) & 0xFFFFF000);
		if (pta == nullptr) {
			pta = alloc_page_ta(memman);
		} else {
			pta = (PAGE_TA*)(((unsigned int)pta) + LADDR_K_BASE);
		}

		sub_end_laddr = utils::min(end_laddr, (i + 1) << 22);
		sub_size = utils::max(0, sub_end_laddr - sub_start_laddr);
		map_page_addr2addr(pta, sub_start_laddr, sub_size, sub_start_paddr, tamode);// 填充pta指向的页表
		sub_start_paddr += sub_size;
		sub_start_laddr += sub_size;
		set_page_ta2de(pagede, pta, i, demode);
	}
}
```

需要注意的是，分页结构要求页表映射的内存是按4k对齐的，即线性地址的一页映射物理内存一帧。而作者之前编写的`memman_alloc_4k`函数仅仅保证了内存区域大小4k对齐，因此我们要对该函数进行修改，让它分配的空间在初始地址和内存大小都按4k对齐。

除了用户程序的页表外，我们还需要把内核程序的页表加入到用户态页目录里面，这样的话，用户态程序调用内核中的api执行内核程序时，就不用更变CR3,直接从当前的task（带有我们准备的用户态页目录）里面映射到内核态的代码了

用户态task的分页：
```
cr3: 0x00000077e000
0x00000000-0x00000fff -> 0x000020000000-0x000020000fff  /* 低线性地址区域用户程序 */
0xc0000000-0xdfffffff -> 0x000000000000-0x00001fffffff  /* 高线性地址区域内核程序 */
0xe0000000-0xffffffff -> 0x0000e0000000-0x0000ffffffff  /* 高线性地址区域硬件区域 */
```

编写函数执行这一拷贝过程
```cpp
void copy_page_de2de(PAGE_DE* fromde, int fromstart, PAGE_DE* tode, int tostart, int count) {
	for (int i = 0; i < count && fromstart + i < PAGE_DE_ENTRY_NUM && tostart + i < PAGE_DE_ENTRY_NUM; ++i) {
		tode->entrys[tostart + i] = fromde->entrys[fromstart + i];
	}
}
```

增加两项用户态的gdt
```cpp
	set_segmdesc(gdt + ((unsigned int)__USER_CS >> 3), 0xFFFFFFFF, 0, AR_CODE32_ER + 0x60);
	set_segmdesc(gdt + ((unsigned int)__USER_DS >> 3), 0xFFFFFFFF, 0, AR_DATA32_RW + 0x60);
```

以用户态运行我们加载的程序
```cpp
	start_app(0x1b, __USER_CS, esp, __USER_DS, &(task->tss.esp0));// 入口地址0x1b,那里是一个jmp跳板
```
运行hello
![](/images/blog/os/21.png)


可能会质疑如果将内核的页表放到用户态程序的页目录里面会不会导致从用户态直接访问内核数据，毕竟我们绕过了段表，段表的limit已经不能起保护作用了。
实际上是不用担心的，因为内核页表的flag中设定了User位为0，只允许内核态代码访问。

编写以下程序`touch_kernel.cpp`来测试：
```cpp
void HariMain() {
	int* kp = (int*)0xC0000000;
	(*kp) = 0xFFFFFFFF;
}
```
![](/images/blog/os/22.png)
bochs检测到了页错误PE
![](/images/blog/os/23.png)

至此，不考虑虚拟内存的用户态分页实现完成


