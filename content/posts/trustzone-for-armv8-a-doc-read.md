---
title: "TrustZone for Armv8-A 概念梳理"
date: 2021-10-07T16:53:55+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Reading
draft: false
---


# TrustZone for Armv8-A

# Links

- [https://developer.arm.com/architectures/learn-the-architecture/trustzone-for-aarch64](https://developer.arm.com/architectures/learn-the-architecture/trustzone-for-aarch64)

# key points

- EL3在任何时候都应该被归类于Secure state的一部分
- 地址空间
    - S.EL0/1和NS.EL0/1分别属于两个**不同且独立的虚拟地址空间**，在安全状态不会使用NS.EL0/1的地址转换，同样，在非安全状态不会适应S.EL0/1的地址转换。
    - **物理地址空间被划分为Secure和Non-secure**
        - Non-secure world的虚地址只能被翻译到Non-secure的物理地址空间
        - **Secure world的软件可以访问Secure和Non-secure两种物理地址空间**
        - 为了区分这两个物理地址空间，物理地址使用前缀`NP:`和`SP:`来标识。**虽然物理地址一样，但是因为前缀不一样，它们就表示不同的内存位置（存的数据可以不一样）**，就好像他们在地址总线上多了位一样：
            
            ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled.png)
            
            - cache的tag中也包含了这个指示位，Non-secure状态下无法影响Secure状态的cache。
- SMC
    - 执行SMC（secure monitor call）时，硬件不会自动进行寄存器值的备份，需要编写软件实现。
    - **在EL1执行的SMC可以被在EL2的hypervisor拦截**，因为hypervisor可能通过这种方式模拟虚拟机所看到的固件接口（firmware interface）。
    - **SMC指令不能在EL0或者Security state时执行**
- 关于虚拟化
    - 从虚拟化从Armv7-A引入直至Armv8.3之前，EL2只在Non-secure世界存在。从Armv8.4-A开始，Secure世界也可以存在EL2了，处于这些考虑：
        - 一些TA可能依赖于在特定的TOS上运行，这意味着要运行多个Trusted kernels，
        - 出于最小化特权原则，firmware中的一些功能需要被移出EL3
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%201.png)
        
    - 与完整的hypervisor程序不同，S.EL2通常托管安全分区管理器（Secure partition manager，SPM），它允许创建隔离分区，这些分区无法查看其他分区的资源。每个分区可以运行各自的TOS和Trusted Services
- 系统架构System architecture
    
    ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%202.png)
    
    - bus secure & bus non-secure
        - bus secure意味着当前总线只能访问安全地址空间；bus non-secure 意味着只能访问非安全地址空间。这是由总线上的`AxPROT[1]`位定义的
        - 但是bus secure和non-secure并非由当前处理器的secure state决定，因为secure state的processor也可以发起bus non-secure的访问。
    - **对bus slaves的访问控制**：
        
        为支持TrustZone，通过processor和外设之间的**互联系统（Interconnect system）**将外设分为4类别：
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%203.png)
        
        - **Secure**: 只能在bus secure时访问，拒绝non-secure访问
        - **Non-secure**: 只能被bus non-secure时访问
        - **Boot time configurable**: 在启动时，系统初始化软件可以控制设备为Secure或者Non-secure。（默认是Secure）
        - **TrustZone aware**: 互联系统允许任何类型的访问通过，这意味着被连接的设备需要自己实现隔离(isolation)
            - 一个例子是对于片外DDR内存，可以在processor和DDR加入一个`TZASC(TrustZone Address Space Controller)`并对互联系统设计为TrustZone aware，然后由TZASC来控制对内存的安全访问。同时对TZASC自身的访问又是Secure only的
                
                ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%204.png)
                
    - **对bus masters的访问控制：**
        
        总线上除了processor，还可能有一些别的masters，如GPU和DMA Controller。这些设备的总线访问控制被分为下面几类：
        
        - **TrustZone aware**：这类master（包括processer）包含对TrustZone的感知能力，能够为总线访问提供适当的安全信息（即能够主动设置bus的安全位）
        - **Non-TrustZone aware**：不感知TrustZone,如一些老的IP，解决办法有下面几种：
            - **Design time tie-off**：如果该master只需要访问non-secure或者只需访问secure地址空间，设计人员可以将相应的位设为固定值。
            - **Configurable logic**：一些互联系统如（NIC-400）允许在启动时再将某个master设置为允许访问non-secure或者secure地址空间。与上面的那类类似不过推迟到了系统启动时再设定。
            - **SMMU(System MMU)**：更灵活的一种方案，它就像processor里的MMU一样。在不支持TrustZone的master前面套一个SMMU，这样在该master发出访问时，会通过对应页表的属性来配置bus的安全位。
    - 中断处理
        - `FIQ(Fast Interrupt Request)`和`IRQ(Interrupt Request)`，是arm中的两种类型的中断：
            - `FIQ`优先级比`IRQ`高，可以打断`IRQ`，并且`FIQ`有一些专用的寄存器`r8-r14`，这意味着`FIQ`的速度会快很多。[参阅](https://stackoverflow.com/questions/973933/what-is-the-difference-between-fiq-and-irq-interrupt-system)
        - 通用中断控制器`Generic Interrupt Controller (GIC)`，可以连接到多个core。
            
            ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%205.png)
            
        - 在GIC规范中，每个中断源被定义为一个`INTID`。
        - `**INTID`整体上可以分两类，Secure 与 Non-secure。每个`INTID`被划分到三个groups中的一个**，且可在运行时动态修改。**GIC通过`INTID`所在的group和当前的security state来决定发出`FIQ`还是`IRQ`中断：**
            - Group 0: Secure interrupt, signaled as FIQ
                - 划分到该组的`INTID` 是一些被EL3处理的中断。
                - 当中断到来时，总是以`FIQ`形式通知
            - Secure Group 1: Secure interrupt, signaled as IRQ or FIQ
                - 其余安全中断源都会被划分到这里，在`S.EL1`或者`S.EL2`中被处理。
                - 如果processor当前是Secure state，则触发`IRQ` ，如果是Non-secure state，则触发`FIQ`。
            - Non-secure Group 1: Non-secure interrupt, signaled as IRQ or FIQ
                - 非安全中断源
                - 如果processor当前是Secure state，则触发`FIQ`，如果是Non-secure state，则触发`IRQ`。
            
            ![一种常见的配置](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%206.png)
            
            一种常见的配置
            
        - 对`INTID`的访问控制？
            - 对于配置为Secure的`INTID`，只有bus secure的访问才可以修改它的状态和配置，否则将读取到`0`值。对于配置为Non-secure的`INTID`，bus secure和bus non-secure的访问都可以对它修改状态和配置。
    - 调试，跟踪和分析
        
        （略）
        
    - 其余设备
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%207.png)
        
        - 一次性编程区域 One-time programmable memory (OTP) or fuses
            - 可以被编程为**设备唯一值（device unique values）**和**OEM的唯一值（OEM unique values）**
            - **设备唯一私钥（device unique private key）**可以被写入在这里，在制造时随机生成唯一密钥。该密钥用于将数据绑定到该芯片。
            - 可以写入OEM公钥的hash值
        - 非易失性计数器（Non-volatile(NV) counter）
            - 一个只能递增且无法重置的计数器，用于防止回滚攻击。
                - 在每次固件更新后增加计数器的值，在启动时，固件的版本会被和NV的值进行比较，防止回滚
        - 可信RAM和可信ROM（Trusted RAM and Trusted ROM）
            - 片上的仅限secure访问的内存。片上意味着**攻击者无法替换**。
            - Trusted ROM：**读取第一个引导代码（first boot code）的地方**。ROM意味着无法重新改写。这意味着我们有**一个已知的、可信的执行起点。**
            - Trust RAM：通常是几百KB的SRAM，**是在安全状态下运行的软件的工作内存**。
            
        
        （略）
        
- 软件架构Software architecture
    - **可信服务TS和非安全世界的通信：**通常使用内存中的**消息队列（message queues）**或者**邮箱（mailboxs）**来实现（注意这个mailbox似乎位于内存中，与核间通信的那个和中断有关的mailbox机制似乎不太一样）。世界共享内存`World Shared Memory (WSM)`有时被用于描述这种通信，这些内存位于非安全区域（因为这样一来安全世界也能访问）。
        - 通常是：非安全世界的程序向mailbox中放入一系列请求(requests)，然后调用内核驱动。后者负责和TEE之间的低级通信，如为消息队列分配内存并将其注册到TEE。之后内核驱动调用SMC将控制权交由EL3，TOS的kernel调用所请求的TS，后者从消息队列读取并处理请求。
            
            ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%208.png)
            
    - **Scheduling：**
        - 一些服务会明确调用EL3层的firmware。例如，电源管理请求Power State Coordination Interface (PSCI)。它通常是阻塞的，这意味着当操作完成时，控制权才会回到non-secure world。
        - TEE的运行在non-secure中的scheduler的控制之下。意味着DoS攻击难以避免，存在**可用性问题**。
            - 一个典型实现是：在Rich OS运行一个daemon，它负责接收请求SMC将控制权交给TEE。随后TEE运行并处理未完成的请求。**直到下一个调度器信号（scheduler tick）或者中断信号，才将控制权交回给Rich OS。**
        - 可用性问题的解决办法
            - 设计软件栈来提供可用性。GIC允许Secure interrupts的优先级高于Non-secure interrupts，以防止在非安全状态下阻止Secure interrupts的发生。
    - TEE与Non-secure虚拟化环境的交互
        - 虚拟化环境（`NS.EL0`/`NS.EL1`）中使用SMC来访问firmware function和Trusted service function。其中一个例子是firmware function中包括电源管理相关的功能。为了虚拟化这一部分，这些firmware function会被`NS.EL2` 层的hypervisor拦截并以模拟的方式来替代。
            
            ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%209.png)
            
    - 启动与信任链（chain of trust）
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%2010.png)
        
        - **boot ROM**：这部分通常非常小而且简单，功能是从闪存(flash)中加载和验证第二阶段引导代码(second stage boot code)。
            - 在ROM中，可以避免改写
            - 在芯片上，防止被替换
        - **second stage boot code**: 位于flash中。执行系统初始化，如
            - 为片外DRAM启动memory controller
            - 加载并验证将在Secure state和Non-secure state运行的映像文件。如TEE和UEFI。另外，Trusted Firmware（EL3）也由该阶段所启动。
    - Trusted Firmware
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%2011.png)
        
        - Trusted Firmware是一个安全世界软件的开源实现
            - SMC Dispatcher 负责处理传入的SMC，决定哪些在EL3处理，哪些被转发到TEE。
            - 还提供了处理system IP（比如互连interconnect系统）的代码。芯片供应商需要提供处理定制IP或者第三方的IP的代码，包括特定于SoC（SoC-specific）的电源管理。
    - Encrypted filesystem 加密文件系统
        - 在一些场景下，用户数据需要文件系统级的加密，防止设备丢失后的数据窃取。在通过用户的验证后，才允许解密文件系统。文件系统解密流程如下：
            
            ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%2012.png)
            
            - Encrypted Filesystem Key被载入到片内可信RAM中，使用片内的一次编程的master device unique key解密。
            - 将解密后 的Filesystem Key传输到一个只能Secure状态下访问的，加密引擎(crypto engine)或内存控制器(memory controller)的寄存器中。
            - 之后对flash中的文件系统的访问都将使用寄存器中设定的密钥进行加解密。
    - 固件firmware的OTA升级
        - 固件升级要求保证可信性、不可回滚性。通常使用以下方案：
            - 新firmware的image在Non-secure环境获得，并不保证其机密性，但是通过签名和OEM公钥来保证其完整性。image被放置在内存中，并向Secure state发出安装请求。
            - Secure state中的代码负责认证，使用OEM的公钥来保证。OEM通常存在片外flash中，因此它也不保证机密性。但可以通过在片内存储OEM公钥的hash来保证其真实性(authenticity)，因为片上存储很贵。
            - 假设通过检查，那么image将被安装，并且NV计数器将会增加
        
        ![Untitled](/images/TrustZone%20for%20Armv8-A%2088d036d115df467e818205433b986fa7/Untitled%2013.png)
        
    - Trusted Base System Architecture (TBSA): gives guidance on system architecture.
    - Trusted Board Boot Requirements (TBBR): gives guidance on booting.