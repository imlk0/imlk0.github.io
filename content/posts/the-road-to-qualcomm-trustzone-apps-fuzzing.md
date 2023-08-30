---
title: "[RECON Montreal 2019] The Road to Qualcomm TrustZone Apps Fuzzing 文章阅读"
date: 2021-10-29T19:38:45+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Fuzzing
  - Reading
draft: false
---

- [https://research.checkpoint.com/2019/the-road-to-qualcomm-trustzone-apps-fuzzing/](https://research.checkpoint.com/2019/the-road-to-qualcomm-trustzone-apps-fuzzing/)
- [https://cfp.recon.cx/media/tz_apps_fuzz.pdf](https://cfp.recon.cx/media/tz_apps_fuzz.pdf)
    
    [tz_apps_fuzz.pdf](%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/tz_apps_fuzz.pdf)
    

# Abstract

作者的目标是对trustlet的command handler函数进行AFL测试。

作者设计了一个loader程序，可以在Android设备的normal world加载并运行trustlet。为了解决syscall的处理问题，作者向QSEOS中加载修补过的trustlet副本作为proxy trustlet。为了能够加载被修补过的代码，作者利用了两个1day漏洞来绕过QSEOS对trustlet的的校验流程。最终使用AFL测试工具完成了测试。

# Backguard

- secapp range：cmblib库和所有的trustlet都被加载到物理内存中的一个名为secure app region的区域内。该区域的地址可以从Android dmesg日志中找到
    
    ![Untitled](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled.png)
    
- trustlet的内存空间无法被别的trustlet访问
- trustlet的内存分配请求将被在这个trustlet自身的数据段中进行
- trustlet的栈区域是trustlet的数据段区域(data segment region)的一部分
- `R9`寄存器始终指向该trustlet的数据段的初始地址
- trustlet的command handler函数签名：
    
    ```c
    int __fastcall cmd_handler(unsigned __int8 *in, unsigned int in_size, 
    														unsigned __int8 *out, unsigned int out_size)
    ```
    
    ![一个command handler函数的例子](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled%201.png)
    
    一个command handler函数的例子
    

# 在普通世界中运行TA

## 基本思路

创建一个运行在normal world用户态的程序（**trustlet loader**），它：

- 分配一段rwx权限的内存区域存储trustlet的代码段和数据段。这些内存块的虚拟地址必须与之前观察到的secapp区域的段地址相同
- 将dump出来的段的内容加载到分配出的内存中。
- 准备好缓冲区，用于存储trustlet的command handler的输入和输出
- 将R9寄存器指向数据段的地址，并调用trustlet的command handler函数

## 失败原因：

- **依赖于cmnlib**：command handler在执行过程中调用了来自cmnlib的库函数。
- **系统调用**：command handler使用`SVC`指令调用了QSEOS相关的系统调用，但是Linux Kernel并不能处理这种系统调用

## 待解决问题：

1. 如何获取安全世界中，trustlet和cmnlib的基地址
2. 如何dump trustlet和cmnlib的数据段
3. 如何能在normal world执行trustlet中的syscall

## 解决方案

![Untitled](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled%202.png)

### 修补加载到安全世界中的trustlet

通过字节码修补创建一个proxy trustlet。扩展现有trustlet的command handler函数，增加一个自定义的command ID，例如0x99，这个command ID所提供的服务是：

1. 返回trustlet的基地址
2. 从secapp区域中读取内存
3. 向secapp区域中写入内存
4. 执行一个请求指定的的syscall

前三个自定义功能，能够帮助我们获得cmnlib的数据段地址（例如对于prov这个trustlet，cmnlib的数据段地址被存储在0x83D4偏移处，这种方法是通用的、每个trustlet都可以访问cmblib的内存）。

![新的command ID的处理代码，提供了上面提到的那些功能](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled%203.png)

新的command ID的处理代码，提供了上面提到的那些功能

### 重定向syscall

修改qemu，使其能够特殊处理`SVC 0x1400`和`SVC 0x14F9`，将normal world发来的syscall转发到proxy trustlet里。

### 栈地址不一致问题

在设计之初，normal world的trustlet和secure world的proxy trustlet具有不同的栈地址，本质是loader并没有为调用cmd_handler()设置独立的栈地址。这对于程序的运行没有影响，但是由于syscall的参数可能包含指向用户空间栈上内容的指针。为了确保QSEOS在处理syscall时能够访问到正确的数据，必须在secapp地址范围内为cmd_handler()初始化一个栈，它们都能访问到的地址范围。解决办法是由loader扩展trustlet的数据段（data segment），在跳转到command handler之前，先将loader的SP寄存器指向数据段的末尾。

### 对*prov这个trustlet*具体的修补

- 增加代码
    1. 将代码段的长度从0x6ED0扩展到0x7000
    2. 将0x99这个command ID的处理代码机器指令写入到0x6ED0
    3. 将0x2060处的4个字节替换成`BL 0x6ED0`，即跳到新加入的command ID的处理代码处
        
        ![跳转到command handler的代码](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled%204.png)
        
        跳转到command handler的代码
        
- 为栈腾出空间
    1. 将数据段的长度从0x103F0扩展到0x11000（多出的部分作为栈）

## 如何加载运行修补后的proxy trustlet？

### 从启动流程来看

`Primary Bootloader(PBL, in ROM)` →`Secondary BootLoader(SBL)`→`Little Kernel applications bootloader && QSEOS`->`trustlets`

即使unlock bootloader或者取得root权限也无法打破该流程。

### 使用漏洞

使用两个1-day漏洞CVE-2015-6639、CVE-2016-2431，从而作者得以修改Nexus 6设备上的QSEOS的数据段。作者攻击了QSEOS的验证机制。具体来说：

- QSEOS先验证TA文件中的签名数据是否正确，然后再计算各个段的hash值与记录值进行比较。
- 作者利用代码注入的方式在签名验证通过后，验证hash值前，改写记录的hash值，从而绕过检查。

![Untitled](/images/%5BRECON%20Montreal%202019%5D%20The%20Road%20to%20Qualcomm%20TrustZo%20ace3d28bcbd94d658c3afa71e63193f5/Untitled%205.png)

# Fuzzing of trusted app

到此为止，作者在Android上结合qemu通过模拟的方式运行了一个trustlet的command handler。另外将一个被修补过的trustlet副本作为proxy trustlet加载到真实的QSEOS中。

使用AFL工具测试TA的command handler，并在安装最新rom的Nexus 6设备上发现了prov这个teustlet的一个漏洞。

# 测试别的设备上的trustlet

在Nexus6上运行新的设备上的trustlet，所要付出的努力，比在新设备中利用类似的QSEOS漏洞来创建这样的测试环境要简单的多。

作者提出了两种测试方法：

1. 重用之前的由prov这个trustlet修补成的proxy trustlet，作为新的trustlet在QSEOS中的代理
2. 以每个新的trustlet作为基础进行修补产生proxy trustlet，加载到QSEOS中作为代理

作者使用第二种方法，通过改编LG和三星设备中的trustlet，然后将其在Nexus6上部署，测试发现了额外的几个漏洞：

> *dxhdcp2* (LVE-SMP-190005), *sec_store* (SVE-2019-13952), *authnr* (SVE-2019-13949) and *esecomm* (SVE-2019-13950), *kmota* (CVE-2019-10574), *tzpr25* (acknowledged by Samsung), *prov* (Motorola is working on a fix).
>