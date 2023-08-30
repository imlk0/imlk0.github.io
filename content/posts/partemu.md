---
title: "[useuix sec20]PartEmu: Enabling Dynamic Analysis of Real-World TrustZone SoftwareUsing Emulation 论文阅读"
date: 2021-10-15T13:46:02+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Fuzzing
  - Reading
draft: false
---

# Links

- [https://www.usenix.org/system/files/sec20-harrison.pdf](https://www.usenix.org/system/files/sec20-harrison.pdf)
- 相关源码在2022年3月的三星源码泄漏中出现

# Abstract

- 目标：
    - 为了将一些新的模糊测试技术如feedback-driven fuzz testing带到TrustZone中。
- 挑战：
    - 传统的方法带来的挑战是相应的**模拟通常是不切实际**的（工作量大）
    - 作者分析了对真实的TZOS进行软硬件模拟所需要的工作。发现这些TZOS**只依赖于有限的硬件和软件组件**，可以只选择这些子集来模拟。
- 工作：
    - 实现了PartEmu，一个可以运行四个现实TZOS以及在它们之上的TAs的仿真器。
        - Qualcomm’s QSEE
        - Trustonic’s Kinibi
        - Samsung’s TEEGRIS
        - Linaro’s OP-TEE
    - 基于QEMU和[PANDA](https://panda.re/)实现了一个模块化的框架。整合[AFL](https://github.com/google/AFL)的feedback-driven 模糊测试能力。
- 测试
    - 对来自手机厂商和IoT厂商的194个TA进行分析，在48个发现了先前未知的漏洞，其中几个是可以利用的。
    - 通过测试QSEE TZOS自身，发现了一些通常不会在真实设备上被执行到的，导致程序崩溃的执行路径。

# Goals

- 构建一个模拟器来分析**现实世界的TZ软件**，尤其是：
    - 在一个模拟器中部署四个现实世界的TZOS和对应的TA的闭源二进制镜像。
- **兼容性**：能够运行和现实设备中一样的TZOS和TA
- **重现性**：具有保真性，以便发现的问题能够在真实设备重现
- **可行性**：需要设计可行的硬件和软件仿真工作

# 分析TZOS的依赖

![Untitled](/images/%5Buseuix%20sec20%5DPartEmu%20Enabling%20Dynamic%20Analysis%20of%20ed0a853757124921a3eb26676fa17fe5/Untitled.png)

### 启动时依赖（bootloader、secure monitor）

- (B1)bootloader**向TZOS提供boot information** structure。
    - 包含硬件信息，如RAM的物理地址范围
- (B1)bootloader**加载TZOS**的二进制文件并启动TZOS
- (B2)TZOS启动完成后**将控制权交回给secure monitor**，以及再次调用TZOS所需的信息

### 运行时依赖（TEE driver、secure monitor、TA）

- (R1)CA请求TEE driver**发出`SMC`调用**
- (R2)secure monitor决定是否要**转发给TZOS**
- (R3)TZOS将请求**转发给TA**

### 硬件依赖

- **依赖于硬件来实现访问控制**，例如依赖TZASC、TZPC(Trustzone Protection Controller用于区分外设是secure还是non-secure)来设置内存和中断
- 还可能**依赖密码学协处理器**(cryptography co-processor)，后者能够获取设备唯一硬件密钥（device-unique hardware key）
- TZOS或者secure monitor还**与大多数硬件组件交互**，取决于具体实现

# 如何选择需要模拟的组件

### 软件组件

只**模拟相关的部分**，例如TZOS对bootloader只依赖于加载和设置参数

### 硬件组件

因为secure boot和code signing，无法在真实的设备上运行软件代理。因此需要**通过模拟**的方式实现那些需要的硬件。

### 选择模拟 or 重用的指标

![Untitled](/images/%5Buseuix%20sec20%5DPartEmu%20Enabling%20Dynamic%20Analysis%20of%20ed0a853757124921a3eb26676fa17fe5/Untitled%201.png)

# 软件仿真

### Bootloader

- 和TZOS的耦合：传递硬件信息、加载TZOS、移交控制权
- 和其他组件的耦合：例如与storage controller(e.g., eMMC, UFS)紧耦合

### Secure Monitor

- 和TZOS耦合：TZOS依赖于世界切换，依赖于SecureMonitor提供硬件的API（通常是Secure Monitor与硬件直接交互）
    - TEEGRIS：secure monitor被硬件密钥加密，需要通过逆向TZOS来找出依赖的SMC API
    - Kinibi：只有少数SMC API，并且设计良好。
    - QSEE：相当紧耦合
    - OP-TEE：secure monitor和TZOS是一起编译的，无法解耦
- 和其他组件的耦合：
    - Kinibi：一些硬件组件如厂商特定的密码学协处理器、PRNG，难以模拟
    - QSEE：耦合低，因为QSEE通常直接访问硬件而不通过Secure Monitor

### TEE Driver和TEE Userspace

- TEE Driver和TZOS耦合
    - TEE Driver和TZOS之间的交互：
        - 启动TA
        - 设置CA和TA之间的共享内存
        - 将CA的命令发送到TA
        - 响应TZOS的请求（例如访问normal world文件系统）
    - 同步/异步通信
        - 同步：如QSEE、OP-TEE：将请求作为SMC的参数然后阻塞知道TZOS响应
        - 异步：如Kinibi、TEEGRIS：将请求放在共享的请求/响应队列中。周期性地调用SMC以将控制权交给TZOS。
- TEE Driver和其他组件的耦合
    - TEE Driver可能依赖TEE userspace来处理功能，如从文件系统中读取文件、访问RPMB
        - QSEE、OP-TEE不需要，TEEGRIS、Kinibi需要
- TEE Userspace
    - Kinibi、TEEGRIS、QSEE的镜像是从Android设备上提取的，其中用户空间的二进制文件是为Android编译的。相比于引入对Android的模拟，直接模拟这部分要更容易得多

# 硬件仿真

**TZOS的硬件访问通过MMIO实现**，即硬件寄存器的值通过访问内存地址获得。

### 具有特定的访问模式

![Untitled](/images/%5Buseuix%20sec20%5DPartEmu%20Enabling%20Dynamic%20Analysis%20of%20ed0a853757124921a3eb26676fa17fe5/Untitled%202.png)

- 读常量值
- 写后读
- 读值会逐渐递增的寄存器
- 读随机值寄存器，例如伪随机数生成器
- 轮询(Poll)：寄存器的值在一个特定事件完成后被设置
- Shadow, Commit, and Target：需要写多个寄存器的情况。先写多个影子寄存器，然后原子性地提交，防止在小时间窗口内出现错误

### 定位MMIO地址范围

- Kinibi：允许从启动信息（boot information structure）中指定MMIO范围
- QSEE/TEEGRIS/OP-TEE：均假定特定的内存区域为MMIO
    - QSEE将二进制文件页表信息中，具有non-cacheable属性的范围当作MMIO范围
    - TEEGRIS/OP-TEE：可以从Linux内核的设备树中取得MMIO的范围

### 其余硬件的模拟

只需要额外对三个设备进行仿真：

- ARM标准的**GIC(global interrupt controller)**，QEMU提供
- 有限的**加密硬件**仿真，例如QSEE依赖的加密协处理器。
    - 只需要为QSEE实现一个SHA-2算法，其余TZOS都使用软件实现的加密
- TZEEGRIS依赖一个**标准的RTC**（real-time clock），QEMU提供

# PartEmu的实现

- PartEmu为PANDA增加了一组运行管理API。并在此之上实现了两个模块
    - fuzz testing with AFL：使用AFL进行测试
    - LLVM run module：输出目标的LLVM IR表示，可以被送入到符号分析引擎如KLEE，S2E

### AFL模块

基于[TriforceAFL](https://github.com/nccgroup/TriforceAFL)实现，后者能够让目标程序在QEMU中运行并执行AFL测试，就像运行被测试的正常进程那样。

因为PartEmu需要单独控制启动QEMU，因此作者额外实现了一个代理与AFL进行交互。

**使用AFL时的挑战**：

- 需要为AFL**圈定被测试的目标**（的地址空间范围），例如特定的TA。
    - Kinibi、TEEGRIS：使用8位的[ASID(Address Space Identifier)](https://community.arm.com/support-forums/f/architectures-and-processors-forum/5229/address-space-identifier---asid)来区分不同的TA所在的地址空间
    - QSEE、OP-TEE：不区分ASID，但是可以用程序计数器的值所在的地址空间范围来区分。
        - QSEE：TA的地址空间是在加载TA时，由normal world申请的
        - OP-TEE：在二进制中硬编码内存区域
- **稳定性**：相同的输入应该导致相同的输出，但是面临中断、随机数带来的影响
    - 在运行过程中，禁止到安全世界的中断
    - 在开始测试前fork PartEmu进程，以消除先前的测试导致的状态改变。
    - 伪随机数：用常量值来替代
    - QEMU对翻译块的串联（[translation-block chaining](https://qemu.readthedocs.io/en/latest/devel/tcg.html#direct-block-chaining)）优化会导致AFL错失被串联的块。关闭这种优化带来效率显著降低。作者通过在每个块的末尾增加一个QEMU IR callback来捕获这些错失的块。

### TA Authentication

TA在加载时需要进行两种检查

- 签名检查
    - QSEE：将TA中的根证书的hash值和内存中存储的hash值比较，这块内存区域是被映射到[OTP fuses](https://electronics.stackexchange.com/a/455773)上的。难以也没有必要从真实设备上取得这个hash值，因为它们在不同厂商之间并不通用。作者的做法是直接从TA的根证书中计算hash值
    - Kinibi、OP-TEE、TEEGRIS的TA认证使用在TZOS中硬编码的公钥来验证签名
- 版本检查（防止回滚）
    - 能够接受的最小TA版本信息通常被存储在RPMB中，作者使用两步来绕过：
        - 修改TA二进制文件中的版本号为0，使用自己的签名来重新签名。
        - 模拟RPMB接口，在查询最小可接受TA版本时提供0值

作者通过绕过这两种检查，可以获得的能力：

- 编写和部署自定义TA
- 允许在使用相同类型的TZOS的厂商的不同固件之上，测试TA
- 允许为TA文件插桩，进行性能优化等

# Evaluation

分为3部分

- 量化需要进行的软硬件模拟，以显示其可行性
- 使用AFL来查找真实世界中的漏洞案例，以证明仿真的有效性
- 在真实设备上评估仿真结果的可复现性

### 仿真的程度

目标

- QSEE v4.0 (Android)
- Kinibi v400A (Android)
- TEEGRIS v3.1 (Android)
- 32-bit OP-TEE (IoT)

实现：52个数据字段、17个SMC调用、235个MMIO寄存器、额外三个外设

TZOS更新：对于不同版本的TZOS之间，只需少数的修改就能够支持

### Fuzz Testing TAs

数据：收集了**12个厂商**的**16个TZOS镜像文件**，都属于上面四种TZOS。一共获得**273个TA**，**去重后一共194个TA**。

测试方法：

- 编写了运行在正常世界的Linux Kernel驱动程序（对于TEEGRIS的测试），或者是运行在正常世界的用户空间的程序(as a normal-world stub)，通过PartEmu的API与AFL模块通信，接收AFL提供的fuzzing输入。
- 程序请求TZOS加载TA并设置共享内存
- 为TA设置fuzz输入，通过SMC将控制交给TA
- 通过返回值来检测crash，所有这些TZOS都会通过特定的返回值表明TA已经崩溃

测试结果：

- 194个TA中崩溃48次

![Untitled](/images/%5Buseuix%20sec20%5DPartEmu%20Enabling%20Dynamic%20Analysis%20of%20ed0a853757124921a3eb26676fa17fe5/Untitled%203.png)

- 通过手动逆向分析每一次崩溃的原因，将崩溃相关的参数分类为：机密性(confidentiality)、完整性(integrity)、可用性(availability)：
    
    ![Untitled](/images/%5Buseuix%20sec20%5DPartEmu%20Enabling%20Dynamic%20Analysis%20of%20ed0a853757124921a3eb26676fa17fe5/Untitled%204.png)
    
    - 可用性方面：共享单个TA实例的问题
        - QSEE：所有CA共享一个TA实例
        - Kinibi、OP-TEE、TEEGRIS：由一个属性flags控制是否是单实例TA
    - 机密性和完整性：
        - 根据TA的不同功能危害不同，作者声称能够演示三种情况：
            - 读写RPMB
            - 泄漏DRM密钥
            - 破解一次性密码TA
- 作者发现这些错误存在一定的模式
    - 来自normal world的调用顺序的假设
    - 解引用来自normal world的未经验证的指针
    - 未验证对来自normal world的缓冲区数据是否是合法的类型

## 能否重现崩溃？

48个崩溃中，有24个拥有相应的设备，并且这24个都能够在真实设备上重现。

- 这其中包含了2个需要访问未被仿真的硬件的TA
- 在剩余的crash中，还有3个TA也访问了专用硬件。
- 即使保守地认为这三个TA是假阳性，PartEmu也**拥有45/48（93%）的真阳性率**

## Case: Fuzz Testing TZOS

测试方法：在内核驱动中利用AFL生成的输入，对QSEE4.0的SMC API进行模糊测试

结论：

- AFL共识别到124种SMC，并在其中3个里触发crash。
- 这些crash只影响TZOS的可用性，对安全的影响有限。
- 导致崩溃的代码路径通常不会在真实设备中触发，除非正常世界（如内核驱动部分）被攻击者破坏。

## 展望

### Dealing with Stateful TAs

- 基本块的覆盖率平均只有17.7%。
- 多数TA内部有有限状态机，需要一连串的输入来驱动它们进入有趣的状态
- 作者的测试中每次只会向一个新的PartEmu实例发送一个消息

### Hardware Roots of Trust

- PartEmu无法模拟硬件信任根，例如出厂时烧写的密钥，一些远程认证相关的任务无法被测试覆盖。

### Performance

- PartEmu运行在x86机器上，无法利用ARMv8的硬件虚拟化
- 对于QSEE\OP-TEE\TEEGRIS，AFL每秒运行10-25次执行。对于Kinibi由于作者进行优化，能够每秒运行125次执行
- 作者计划探索直接在ARMv8硬件上运行PartEmu（没找到）