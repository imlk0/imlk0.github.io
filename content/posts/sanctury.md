---
title: "SANCTUARY: ARMing TrustZone with User-space Enclaves 论文阅读"
date: 2021-09-22T14:59:59+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Reading
draft: false
---

# Links

- [https://www.ndss-symposium.org/ndss-paper/sanctuary-arming-trustzone-with-user-space-enclaves/](https://www.ndss-symposium.org/ndss-paper/sanctuary-arming-trustzone-with-user-space-enclaves/)
- 未找到源码

# Overview

结合TrustZone，实现在Normal World加载运行Security Sensitive Applications，提供了有点类似于intel sgx的那种模式。解决了TrustZone TA作者不易将程序部署到arm设备上的问题。

整体结构图如下。

![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled.png)

# Key points

- Secure World运行修改版的OP-TEE
    - 在OP-TEE中嵌入了一个**STAS（Static Trusted APP**），运行在EL1层，用于辅助管理当前运行中的Sanctuary 实例。
    - 在OP-TEE之上运行自己实现的两个TA
        - **Proxy TA**用于提供remote attestation
        - **Sealing TA**用于提供sealing
- Normal World运行Linux，和不可信的**Legacy APP（LA）**
    - 部署一个内核模块：负责加载用户空间提供的SA二进制文件，**在启动Sanctuary Application（SA）前分离一个cpu核**，并将控制权交给STA。
- Sanctuary Instance：运行在Normal World，被限制只能访问自己的内存空间，而无法访问Legacy App和 Legacy OS的空间。包含Sanctuary App（SA）和Sanctuary Library(SL)
    - **SA**：用户提供的程序，运行在EL0
    - **SL（Sanctuary Library）**：运行在EL1，在文章中为修改后的Zircon微内核，和用户提供的程序一起打包，但是由于和SA在一个内存空间，通常也不可信。
        - SL的验证："In our prototype, the STA verifies the SL using a pre-configured signature"
- **Trusted Firmware**是信任锚(trust anchor)，运行在EL3，负责上下文切换
- **TZASC(TrustZone Address Space Controller)** TZC-400模块
    - 针对多个核心限制地址空间的访问权限（可以精确到核心号，Normal/Secure Mode，Memory Area）
    - BUS master ID：和CPU核心的ID一致
    - 内存划分为多个region
        
        每个region可以设置地址范围（base, top），同时使用一个32位的寄存器来设置(按bit设置)各个bus master ID对应的设备对该区域的读写权限：（因此似乎只支持最多16个bus master ID）
        
        ![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%201.png)
        
- Legacy OS(Linux)中的模块KM负责在TZASC开辟的共享内存上建立LA和SA之间的通信（这个信道是不安全的）。而SA和TA之间的通信使用secure shared memory channel。

![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%202.png)

- evaluation环节
    - Micro benchmarks：
        - 测量LA-STA/LA-TA/LA-SA/SA-TA之间的通信耗时
        - 测量Sanctuary启动环节的4个阶段（Load Sanctuary binaries，Shut down core，Lock & Verify，Start Sanctuary）耗时
        - 测量Sanctuary关闭环节耗时
    - Use-Case: OTP Generation for Two-Factor Authentication
        
        ![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%203.png)
        

# Security Analysis

## Adversary model

- 攻击者可以破坏所有normal world的软件，甚至包括EL2级的虚拟机监视器。但是不考虑攻击者破坏secure monitor mode（EL3）和secure world的情形。
- 不考虑侵入性的物理攻击
- 不考虑DoS攻击，这意味着Sanctuary不提供可用性保证

## How to protect

- **Binary Integrity**：载入的SA的完整性问题
    - local attestation: SL是由Sanctuary提供的，Sanctuary在安全内存中存储了SL的签名，在启动之前会**检查用户载入的SL的完整性**。
    - remote attestation：开发者可以**使用remote attestation来校验SA的完整性**。当SA连接到服务器时，TEE功能被用于创建到服务器的安全连接。在服务器提供敏感数据前，可以请求STA创建SA的一个签名，发给服务器验证，确保SA处于有效状态。
- **Code and Data Isolation**：代码和数据的隔离
    - **内存隔离**：在校验SL之前，Sanctuary instance的内存隔离就由trustzone实施（这里应该是指的TZASC），只有被选定的core可以访问。
    - **执行隔离**：且**被选定的core总是从ATF(EL3)中开始**运行，然后跳转到SL中的一个固定的地址。在sanctuary instance启动过程中，SL会确保所有**来自系统中断控制器（system-wide interrupt controller）的由其他核触发的中断**被禁用。另外，只有核心自身可以配置GIC接口，从而sanctuary instance的执行不会被其它核心所打断。只有这个core自己可以关闭自己。
    - [x]  Q: 通常多核心处理器是怎么处理中断的？(x86为例)
        - 每个core可以有自己的中断向量表，core内部中断被发送到产生它们的core，而外部中断将被发送到一个仲裁核心（arbirary core）。可以通过对APIC进行编程来配置中断被路由到哪个core。[参阅](https://stackoverflow.com/a/10235423/15011229)
            - APIC：与传统可编程中断控制器（PIC，如intel 8259）不同，现代计算机使用APIC技术。每个core内部有LAPIC（Local APIC），I/O APIC芯片组中包含IOAPIC，后者与外围设备相连。LAPIC和IOAPIC之间使用APIC总线通信（另说现在已经合并入系统总线）。[参阅](https://zhuanlan.zhihu.com/p/393195942)
        - 多核心CPU的启动：[参见](https://wiki.osdev.org/Symmetric_Multiprocessing)
            - 启动时多个core竞争成为BSP(bootstrap processor)，负责进行一系列的初始化。未竞争成功的core作为AP(application processor)，BSP和AP之间通过处理器间中断IPI(Inter-Processor Interrupt)进行通信，例如在x86平台上BSP通过INIT IPI和SIPI(STARTUP IPI)来激活AP
    - **防止内存数据注入/泄露**：在sanctuary instance被锁定直至解锁前，会使**用固定值覆盖SL和SA之外的内存**，包括安全共享内存。在instance被释放前，会被重置为初始状态，因此内存中不包含SA的数据。
    - **数据传递安全**：在运行期间，SANCTUARY会确保敏感数据只传递给锁定的SANCTUARY实例并从该实例接收。**当（sanctury core）执行切换到安全世界时，TF验证调用是从SANCTUARY核发出的**。 并且安全世界中的TA会使用STA来检查SANCTUARY实例是否处于正确状态，然后再向安全世界和SA之间共享的内存读写任何数据。
    - [x]  Q: 多核心的设备中，TOS可以使用多个core吗
        - 可以
            - 目前运行OP-TEE所运行的core取决于ROS，即它与ROS中执行SMC指令的核心相同。这意味着OP-TEE实际上并没有自己的任务调度程序，而是使用Linux内核进行调度。参阅OP-TEE[文档中的F&Q](https://optee.readthedocs.io/en/latest/faq/faq.html#q-can-i-limit-what-cpus-cores-op-tee-runs-on)：
            - 可以在不同的core上运行多个TA。但是它并没有pthreads或者类似的概念。[参阅](https://optee.readthedocs.io/en/latest/faq/faq.html?highlight=multi%20core#q-is-multi-core-ta-supported)
- **Secure Storage**：安全存储
    - Sealing：STA使用**从加载的SA的二进制哈希值派生的密钥**来密封数据。
    - persistent storage：对于持久性存储，取决于TEE自身的实现。可能被存储到设备上的文件中，或者存储到RPMB中。
- **Cache Attack Resilience**：缓存攻击的适应性
    
    作者假设的设备为L1独占，L2多核间共享
    
    - **Direct Attacks**：直接攻击。通常认为攻击者控制了LOS（EL1），并可以操控页表映射到被保护的物理地址。
        - L1：运行sanctuary的core独占自己的L1，且在退出前会使缓存失效（invalidating）因此**L1没有威胁**。
        - L2：作者介绍了两种方法来规避
            - 更改硬件，将基于身份的过滤（identity-based filtering）扩展到L2上
            - **将sanctuary的内存区域配置为non-cacheable**，这样该区域内存数据不会驻留在L2中，相当于没有L2，**对此作者做了性能测试实验验证**。
                
                > However, **even without using the L2 cache for the SANCTUARY core**, the complete SANCTUARY setup **can still be performed in around 450ms**. If the identity-based filtering feature is implemented in the cache, a setup time around 200ms can be achieved.
                > 
                
                ![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%204.png)
                
                ![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%205.png)
                
                ![Untitled](/images/SANCTUARY%20ARMing%20TrustZone%20with%20User-space%20Enclave%2079951592f9574096a237fb5d05f2b3f4/Untitled%206.png)
                
    - **Side-Channel Attacks**：侧信道攻击。
        - L1：没有威胁，和之前的原因一样
        - L2：对内存区域实现identity-based filtering（即通过TZC-400进行的内存隔离策略）并不能抵御缓存侧信道，因此需要扩展到L2上，例如使用cache partitioning之类的方法
- **Malicious Sanctuary App**：恶意的SA
    - 对SL的威胁：SA运行在EL0中，SL运行在EL1中
    - 对secure world的威胁：即使能够提权到EL1，仍然无法访问安全内存，因为SA运行在normal world
    - 对LOS（Legacy OS）的威胁：sanctuary所在的core被限定能够访问内存区域，无法访问LOS
    - 对其余SA的威胁：提权到EL1后，可能对其他SA有威胁，但是因为sanctuary的设计是同时运行一个SA，因此无法威胁其它SA.


## 相关工作

### 作者后续工作

[[USENIX Security 21][CURE: A Security Architecture with CUstomizable and Resilient Enclaves](https://www.usenix.org/conference/usenixsecurity21/presentation/bahmani)](https://www.notion.so/USENIX-Security-21-CURE-A-Security-Architecture-with-CUstomizable-and-Resilient-Enclaves-3296fc02fb7946da9bdd53f2d6910053?pvs=21)

### 类似工作

- [Ginseng: Keeping Secrets in Registers When You Distrust the Operating System](https://www.ndss-symposium.org/ndss-paper/ginseng-keeping-secrets-in-registers-when-you-distrust-the-operating-system/)
- [TrustICE: Hardware-Assisted Isolated Computing Environments on Mobile Devices](https://ieeexplore.ieee.org/document/7266865)
- [Cache-in-the-Middle (CITM) Attacks: Manipulating Sensitive Data in Isolated Execution Environments](https://csis.gmu.edu/ksun/publications/CITM_CCS20.pdf)
