---
title: "OP-TEE: Open Portable TEE 概念梳理"
date: 2021-11-27T09:14:37+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Reading
draft: false
---

# Links

- [https://www.trustedfirmware.org/](https://www.trustedfirmware.org/) Linaro的介绍可信固件的网页
- [https://www.op-tee.org/](https://www.op-tee.org/) OP-TEE官网
- [https://github.com/OP-TEE/](https://github.com/OP-TEE/) OP-TEE仓库
- [https://optee.readthedocs.io/en/latest/](https://optee.readthedocs.io/en/latest/) 文档
- [https://www.kernel.org/doc/html/latest/staging/tee.html](https://www.kernel.org/doc/html/latest/staging/tee.html) Linux TEE subsystem

# Overview

## Architecture (in ARMv8)

![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled.png)

- Definition
    - CA：Client Application
    - TA：Trusted Applcation
    - TOS：Trusted OS（OP-TEE ...）
    - REE：Rich Execute Environment
    - TEE：Trusted Execution Environment
    - ATF：ARM Trusted Firmware
- SMC(Secure Monitor Call) ，从Normal world EL1发起调用，进入EL3，然后跳转到Secure world
- 常见ARM启动流程
    
    ![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%201.png)
    

## Trustzone Hardware

![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%202.png)

- AXI(Advanced eXtensible Interface)：先进可扩展接口系统总线。TurstZone为其增加了一个额外的控制信号位称为**非安全状态位（NS bit, Non-Secure bit）**
    - AWPROT[1]：表示总线写事务是否安全（1表示不安全，0表示安全）
    - ARPROT[1]：表示总线读事务是否安全
- APB(Advanced Peripheral Bus，APB)：外设总线：APB通过AXI-to-APB桥连接到系统总线上。
- TZASC(TrustZone Address Space Controller)TrustZone地址空间控制组件：一是AXI总线上的一个主设备，**TZASC能够将从设备全部的地址空间分割成一系列的不同地址范围**。
- TZMA(TrustZone Memory Adapter)：TrustZone内存适配器组件。允许对片上静态内存（on-SoC Static Memory）或者片上ROM进行安全区域和非安全区域的划分。
- TZPC(TrustZone Protection Controller)：TrustZone保护控制器组件。通过设定TZPCDECPORT信号和TZPCR0SIZE等相关控制信号，用来告知APB-to-AXI对应的外设是安全设备还是非安全设备
- TZIC(TrustZone Interrupt Controller)：TrustZone中断控制器。TZIC的作用是让处理器处于非安全态时无法捕获到安全中断。

## OP-TEE与Liunx TEE subsystem

- 用户空间程序通过 `ioctl()`和Linux TEE子系统通信（CA和`/dev/tee*` , tee-supplicant和`/dev/teepriv*`），然后OP-TEE驱动使用SMC调用约定（SMC Calling Convention (SMCCC)，是一种使用 `smc` 汇编和安全世界通信的约定）和OP-TEE通信
    
    ![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%203.png)
    
- 目前Linux 的TEE子系统中包含对OP-TEE和AMD-TEE的支持，后者是AMD Platform Security Processor（PSP，AMD平台安全处理器，是一个arm处理器，被用于提供安全服务，与AMD SEV技术无关）

## **GlobalPlatform API**

- **每个TA由一个UUID标识**
- **TEE Client AP**I: CA使用与TEE交互的API一共5个，一般调用顺序如下：
    
    OP-TEE似乎未给normal world加载TA的能力
    
    ```c
    TEEC_InitializeContext(...)
    TEEC_OpenSession(...)
    TEEC_InvokeCommand(...)
    TEEC_CloseSession(...)
    TEEC_FinalizeContext(...)
    ```
    
    - 在`TEEC_InvokeCommand()`中使用 `commandID`参数来标识待执行的命令，最多支持4个参数，每个参数的类型允许动态指定，可以是：
        
        ```c
        /* Parameter Type Constants */
        #define TEE_PARAM_TYPE_NONE             0
        #define TEE_PARAM_TYPE_VALUE_INPUT      1
        #define TEE_PARAM_TYPE_VALUE_OUTPUT     2
        #define TEE_PARAM_TYPE_VALUE_INOUT      3
        #define TEE_PARAM_TYPE_MEMREF_INPUT     5
        #define TEE_PARAM_TYPE_MEMREF_OUTPUT    6
        #define TEE_PARAM_TYPE_MEMREF_INOUT     7
        ```
        
- TEE Contexts：被用于创建CA和TEE之间的逻辑链接，需在TEE Session之前创建，当CA完成了在secure world运行的任务之后，它应该释放掉该context.
- TEE Sessions：CA和某个特定的TA之间的逻辑链接，这意味着CA和某个特定的TA之间的通信已经创建
- **TEE Internal Core API：**提供给TA使用，主要包括以下功能
    
    ```
    1. **Trusted Storage API for Data and Keys**
    2. Cryptographic Operations API
    3. Time API
    4. Arithmetical API
    ```
    
    - 其中可信存储允许存储普通Data和Keys，**每个存储的Object由一个Id标识**。
        - 存储类型可以被指定为
            - 瞬态（Transient）：存储于内存中
            - 持久化（Persistent）：可以被同一TA再次加载，要求可以通过恢复出厂设置被清除
        - OP-TEE在实现过程中，持久化数据的存储有两种位置：[参见](https://optee.readthedocs.io/en/latest/architecture/secure_storage.html)
            - `TEE_STORAGE_PRIVATE_REE`存储到REE的文件系统中，由在REE用户态运行的 `tee-supplicant`来辅助完成
            - `TEE_STORAGE_PRIVATE_RPMB`存储到eMMC设备的 **Replay Protected Memory Block (RPMB，重放保护存储块)** 。RPMB 可对写入操作进行鉴权，但是读取并不需要鉴权，**任何人都可以进行读取**的操作，因此存储到 RPMB 的数据通常会**进行加密后再存储**。
                - 对于RPMB存储，其secure key是只能写入一次的OTP，该key从HUK派生，在安全环境（如厂商）中写入
                - 在实际使用中对RPMB的读写需要由不安全世界的tee-supplicant进行辅助，[见](https://optee.readthedocs.io/en/latest/architecture/secure_storage.html#device-access)
                - qemu暂不支持模拟RPMB硬件，但tee-supplicant中实现了对RPMB的模拟
            - 还有一个`TEE_STORAGE_PRIVATE`选项会自动从上面两种位置进行选择一种

### OP-TEE的密钥管理（[参考](https://optee.readthedocs.io/en/latest/architecture/secure_storage.html#key-manager)）

- **Hardware Unique Key (HUK)硬件唯一密钥**，[参考](https://optee.readthedocs.io/en/latest/architecture/porting_guidelines.html#hardware-unique-key)
    
    是每个设备唯一的密钥，用于派生出其他密钥。OP-TEE中没有具体定义其获取方式（默认的值为全0数组），这意味着它可能是**由另一个安全处理器提供**。
    
- **Secure Storage Key (SSK)安全存储密钥**
    
    ![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%204.png)
    
    在OP-TEE启动后从HUK中派生，保存在安全内存（secure memory）中，永远不存储到disk中。这似乎意味着SSK在每次系统启动后都会是一样的值。
    
    其中HUK和Chip ID的获取取决于平台实现。
    
- **Trusted Application Storage Key (TSK)可信应用安全存储密钥**
    
    ![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%205.png)
    
    每个TA一个，通过SSK和TA_UUID派生，这保证了TA加密的数据无法被别的TA解密。
    
    由于SSK是不变的，这种派生似乎意味着TSK对于每个TA始终都是一样的。
    
- **File Encryption Key (FEK) 文件加密密钥**
    
    这个密钥通过伪随机数产生，用于加密/解密存储在文件块（file block）中的数据。同时FEK自身通过TSK加密后存储在元文件（meta file）中
    
    ![Untitled](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%206.png)
    

## RPMB in eMMC

- RPMB 「Replay Protected Memory Block(重放保护内存块)」是eMMC中的一个特别的分区，使用计数器来防止重放攻击（每写入一次计数器加一），允许通过共享密钥的写入保护，其中内容可以任意读取，因此需要先加密后再写入。
- 基本原理
    - 预共享密钥（authentication/security key）
        - RPMB 加密用的security key是对称密钥，只能被写入一次（one-time programmable），通常在安全环境下（如出厂时）烧写到 eMMC 的 OTP 区域
    - 基于消息验证码MAC对请求/响应进行验证
        - HMAC SHA-256
        - 将[283:0]范围内的内容使用预共享的密钥进行加密
        - 读操作的请求帧不需要MAC值（填0x0），但是读操作的响应帧会提供MAC值进行验证
            
            ![RPMB请求/响应帧格式](/images/OP-TEE%20Open%20Portable%20TEE%20a9aa1234bc2646449c45b2bbb557ed52/Untitled%207.png)
            
            RPMB请求/响应帧格式
            
    - 基于write counter的防止写重放
        - write counter也参与到MAC值的校验过程中，检验完成后。会比较帧中的write counter和硬件中记录的counter是否一致。否则拒绝写入并失败
        - 读请求的reply中write counter值为0
        - writer counter的值可以被读出
- RPMB分区可以使用 `mmc`工具进行访问
- 参考
    - [RPMB介绍与使用](https://wowothink.com/8ca78fd8/)
    - [RPMB原理介绍](https://blog.csdn.net/shenjin_s/article/details/79868375)
    - [JEDEC eMMC specification (JESD84-B51)](https://www.jedec.org/sites/default/files/docs/JESD84-B51.pdf)（登陆后可免费下载）