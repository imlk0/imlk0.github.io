---
title: "SoK: Understanding the Prevailing Security Vulnerabilities in TrustZone-assisted TEE Systems 论文阅读"
date: 2022-05-03T15:27:47+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Reading
draft: false
---


- [PDF version](https://www.cs.purdue.edu/homes/pfonseca/papers/sp2020-tees.pdf)

这是一篇IEEE S&P 2020的论文，这篇文章中，作者通过分析过去几年内TrustZone的TEE有关的上百个漏洞，分析存在的安全问题。

- **列举了很多漏洞成因**，部分攻击还举例了相关的工作。
- **列举**出了近几年的**一些的防御工作**

# 总览

## 分析方法论

- 攻击的威胁模型：提出了4个不同程度的威胁模型，表示这些漏洞致力于其中的一些目标
- **被分析的TEE实现：** Qualcomm, Trustonic, Huawei, Nvidia, and Linaro.
- 漏洞数据来源：CVE (CVE databases), SVE (SVE databases), SP (scientific publications), MR (miscellaneous reports), and SC (source code, for OP-TEE only）
- 漏洞分级：表格列举了对已被分配CVE的漏洞的严重等级分布
- 二进制分析：**对TEE系统中的子集进行二进制分析**
    1. 量化每个TEE系统的TCB范围
    2. 确定具体的软件架构
    3. **分析每个TEE实现的内存保护功能**
    
    对于每个TEE系统只逆向分析了其中的某个版本
    
- 对结论的有效性的威胁：由于缺乏POC和CVE描述的不准确，作者对漏洞的分类可能是不准确的。

# 漏洞原因

## architectural issue

作者列出了调研的TEE系统的结构

![截图 2022-05-03 16-38-58.png](/images/%5BIEEE%20S&P%202020%5DSoK%20Understanding%20the%20Prevailing%20Se%2015ffe15649f64bbcbfd22191f0c220ba/%E6%88%AA%E5%9B%BE_2022-05-03_16-38-58.png)

### TEE的攻击面

- T01. SW drivers run in the TEE kernel space
    - 安全世界中的驱动可能是脆弱的但是具有较高的权限级
- I02. Wide interfaces between TEE system subcomponents
    - NW中的kernel暴露了太多的接口给普通程序
    - SW中的kernel给NW的kernel暴露了很多的SMC调用
    - TA给CA暴露了很多cmd
    - SW中的kernel给TA暴露了很多syscall并且很少做限制
- I03. Excessively large TEE TCBs
    - TEE世界中的代码量很大，作者用了一张表格来表示
        
        ![截图 2022-05-03 16-54-54.png](/images/%5BIEEE%20S&P%202020%5DSoK%20Understanding%20the%20Prevailing%20Se%2015ffe15649f64bbcbfd22191f0c220ba/%E6%88%AA%E5%9B%BE_2022-05-03_16-54-54.png)
        

### NW和SW之间的隔离

- I04. TAs can map physical memory in the NW
    - 由于对高效的共享内存机制的需求，一些TEE kernel如QSEE提供系统调用让TA映射任意的NW中的内存
- I05. Information leaks to NW through debugging channels
    - 一些对TA的调试机制如dump stack trace到NW，将log提供给NW能导致地址信息泄露

### 内存保护机制

![Untitled](/images/%5BIEEE%20S&P%202020%5DSoK%20Understanding%20the%20Prevailing%20Se%2015ffe15649f64bbcbfd22191f0c220ba/Untitled.png)

- I06. Absent or weak **ASLR** implementations
    - ASLR机制实施不完善，有些TEE中TA被加载到固定的位置
- I07. No stack cookies, guard pages, or execution protection

### 可信启动

- I08. Lack of software-independent TEE integrity reporting
    - 尽管存在安全启动，但是缺乏向远程第三方安全地报告软件完整性测量结果的硬件机制
- I09. Ill-supported TA revocation
    - 无法正确地处理TA撤销，易受到降级攻击

## implementation issue

### 验证错误Validation Bugs

Examples include buffer overflows, incorrect parameter validation, mishandled integer overflows, etc.

- I10. Validation bugs within the secure monitor
- I11. Validation bugs within TAs
- I12. Validation bugs within the trusted kernel
- I13. Validation bugs in secure boot loader

### 功能性错误Functional Bugs

- I14. Bugs in memory protection
- I15. Bugs in configuration of peripherals
- I16. Bugs in security mechanisms

### 外部错误Extrinsic Bugs

- I17. Concurrency bugs
    - 并发访问文件系统(OP-TEE)
    - TOCTOU漏洞，系统状态的某些方面在条件检查后发生变化（Trustonic、Nvidia）
- I18. Software side-channels

## hardware issue

### 架构影响Architectural Implications

- I19. Attacks through reconfigurable hardware components
    - 一些reconfigurable的平台如FPGA上特有的问题
- I20. Attacks through energy management mechanisms
    - 通过在NW侧调节频率和电压在SW中诱发错误的计算

### 微体系结构侧信道

- I21. Leaking information through caches
- I22. Leaking information through branch predictor
- I23. Leaking information using Rowhammer

# 防御工作

![截图 2022-05-03 19-34-08.png](/images/%5BIEEE%20S&P%202020%5DSoK%20Understanding%20the%20Prevailing%20Se%2015ffe15649f64bbcbfd22191f0c220ba/%E6%88%AA%E5%9B%BE_2022-05-03_19-34-08.png)

## 体系结构防御Architectural Defenses

- D01. Multi-isolated environments
    - 在NW中创建隔离环境
        - 利用TZASC：SANCTUARY、TrustICE
        - NW中的硬件虚拟化扩展：OSP、PrivateZone、vTZ
    - 加强SW中TA的隔离
        - 在SW中实现minimalist hypervisor：TEEv、PrOS
            - 并未使用SW中的硬件虚拟化支持
- D02. Secure cross-world channels
    - 创建安全的NW-SW通道
- D03. Encrypted memory
- D04. Trusted computing primitives

## 实现上的防御Implementation Defenses

- D05. Managed code runtimes
- D06. Type-safe programming languages
    - RustZone
- D07. Software verification
    - 对特定的组件进行形式化验证

## 硬件防御Hardware Defenses

- D08. Architectural countermeasures
- D09. Microarchitectural countermeasures

# 除TrustZone之外的安全硬件技术

![截图 2022-05-03 20-10-26.png](/images/%5BIEEE%20S&P%202020%5DSoK%20Understanding%20the%20Prevailing%20Se%2015ffe15649f64bbcbfd22191f0c220ba/%E6%88%AA%E5%9B%BE_2022-05-03_20-10-26.png)