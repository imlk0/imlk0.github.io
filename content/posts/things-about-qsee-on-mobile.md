---
title: "浅析一加6手机上的QSEE"
date: 2021-10-12T20:11:16+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - QSEE
draft: false
---

# Refer

- [com.qualcomm.qti.qdma 简单介绍](https://blog.csdn.net/wnw_jackie/article/details/113373657)
- [The Road to Qualcomm TrustZone Apps Fuzzing](https://research.checkpoint.com/2019/the-road-to-qualcomm-trustzone-apps-fuzzing/)  [[PDF]](https://cfp.recon.cx/media/tz_apps_fuzz.pdf) [RECON Montreal 2019]
- Qualcomm-[Secure Boot and Image Authentication Technical Overview (v2.0)](https://www.qualcomm.com/documents/secure-boot-and-image-authentication-technical-overview-v20) also [v1.0 version](https://www.qualcomm.com/media/documents/files/secure-boot-and-image-authentication-technical-overview-v1-0.pdf)
- [PartEmu: Enabling Dynamic Analysis of Real-World TrustZone SoftwareUsing Emulation](https://www.usenix.org/system/files/sec20-harrison.pdf) [USENIX 20]
- [https://gtoad.github.io/2019/11/26/TEE-CVE-2015-6639/](https://gtoad.github.io/2019/11/26/TEE-CVE-2015-6639/)

# Keypoints

## 缩写

部分参考自[Refer[1]](#refer)

- **QSEE**: Qualcomm Secure Execution Environment (TZ versions 4.x, 3.x, and 2.x)
- **QTEE**: Qualcomm Trusted Execution Environment (TZ version 5.x)
- **TA**: Trusted Application 也称为**trustlets**
- **HLOS**: High Level OS，即Non-secure世界的OS
- **QTI**: Qualcomm Technologies Inc.
- **QSEECOM**: Qualcomm Secure Execution Environment Communicator
- **QSEECOMD**: QTI Secure Execution Environment Communicator Daemon.

## 关键文件

- /vendor/lib64/libQSEEComAPI.so：用户态程序API。并无源码，但在AOSP中找到一份[QSEEComAPI.h](https://cs.android.com/android/platform/superproject/+/master:hardware/qcom/keymaster/QSEEComAPI.h)头文件
- /vendor/bin/qseecomd：用户态守护进程
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled.png)
    
- /dev/qseecom 、/dev/qsee_ipc_irq_spss: 内核驱动暴露给用户态程序的字符设备接口。
    
    仅在高通设备内核源码中存在，[驱动源码](https://android.googlesource.com/kernel/msm.git/+/refs/tags/android-12.0.0_r0.7/drivers/misc/qseecom.c)
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%201.png)
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%202.png)
    
- 常见的存放二进制TA程序的目录：[来源](https://research.checkpoint.com/2019/the-road-to-qualcomm-trustzone-apps-fuzzing/)
    
    ```
    /firmware/image/
    /vendor/firmware/
    /vendor/firmware/image/
    ```
    
- 调试信息：
    - 源码位置：drivers/firmware/qcom/tz_log.c
    - /proc/tzdbg/：一加Android N以上设备上存在，包含`qsee_log`和`tz_log`两个子文件
    - /sys/kernel/debug/tzdbg/：若设备挂载了debugfs，`tzdbg`目录下存在和trustzone相关实时日志信息。
        - 其中`qsee_log`是安全世界一侧的日志
        
        ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%203.png)
        
    - 此外dmesg中也有一部分内核驱动日志（日志tag是QSEECOM）
        
        ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%204.png)
        

## 设备分区（以oneplus 6为例）

- /vendor挂载了一个单独的分区，存放厂商特定的数据。这里面/vendor/firmware里存放了一部分trustlets
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%205.png)
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%206.png)
    
- /vendor/firmware_mnt里面存放了设备上一部分trustlets的可执行文件，单独在另一个分区里
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%207.png)
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%208.png)
    

## 设备上的**trustlets文件（以oneplus 6为例）**

该设备上的存放trustlets文件的路径已知有两个，`/vendor/firmware/`和`/vendor/firmware_mnt/image/`

（单个trustlet程序被拆分成好几个文件，这里为了显示设备上有哪些trustlet，只列出了主要部分的`.mdt`文件）

- `/vendor/firmware/`：
    
    ```
    -rw-r--r-- 1 root root 6684 2009-01-01 08:00 /vendor/firmware/a630_zap.mdt
    -rw-r--r-- 1 root root 7208 2009-01-01 08:00 /vendor/firmware/cppf.mdt
    -rw-r--r-- 1 root root 6812 2009-01-01 08:00 /vendor/firmware/ipa_fws.mdt
    -rw-r--r-- 1 root root 7208 2009-01-01 08:00 /vendor/firmware/widevine.mdt
    ```
    
- `/vendor/firmware_mnt/image/`，其中值得注意的有一个`alipay.mdt`，还有一个`soter64.mdt`
    
    ```
    -r--r----- 1 system system 7452 2021-05-26 22:51 /vendor/firmware_mnt/image/adsp.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/alipay.mdt
    -r--r----- 1 system system 7260 2021-05-26 22:51 /vendor/firmware_mnt/image/cdsp.mdt
    -r--r----- 1 system system 6876 2021-05-26 22:51 /vendor/firmware_mnt/image/cmnlib.mdt
    -r--r----- 1 system system 7032 2021-05-26 22:51 /vendor/firmware_mnt/image/cmnlib64.mdt
    -r--r----- 1 system system  724 2021-05-26 22:25 /vendor/firmware_mnt/image/cpe_9340.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/cppf.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/dhsecapp.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/dxhdcp2.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/esesvc.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/faceapp.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/fpc1228.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/gfp5288.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/gfp9508.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/gpqese.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/gptest.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/haventkn.mdt
    -r--r----- 1 system system 8412 2021-05-26 22:51 /vendor/firmware_mnt/image/modem.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/securemm.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/sl7000.mdt
    -r--r----- 1 system system 7964 2021-05-26 22:51 /vendor/firmware_mnt/image/slpi.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/soter64.mdt
    -r--r----- 1 system system 6812 2021-05-26 22:51 /vendor/firmware_mnt/image/venus.mdt
    -r--r----- 1 system system 7004 2021-05-26 22:51 /vendor/firmware_mnt/image/voicepri.mdt
    -r--r----- 1 system system 7208 2021-05-26 22:51 /vendor/firmware_mnt/image/widevine.mdt
    ```
    

### trustlet文件格式

并未找到关于这些文件组织形式的官方说明文档，但从一些网络来源可以得出一些结论：

- trustlet可执行文件被拆分成了好几个部分，包括`*.mdt`、`*.bXX`。
    
    ![图源[Refer[2]](https://www.notion.so/Things-About-QSEE-On-Mobile-d705c73739c241e48aab6765102a11b3?pvs=21)](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%209.png)
    
    图源[Refer[2]](https://www.notion.so/Things-About-QSEE-On-Mobile-d705c73739c241e48aab6765102a11b3?pvs=21)
    
- 完整的trustlet是一个标准的ELF格式文件，其中有一个名为Hash Table的Segment（这个段的定义可在[Refer[3]](https://www.notion.so/Things-About-QSEE-On-Mobile-d705c73739c241e48aab6765102a11b3?pvs=21)找到）。
    
    ![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%2010.png)
    
    - 前半部分是元数据和各ELF文件中各segments的哈希值。
    - 签名和证书链：文件中包含证书（Signature）和证书链（Cert Chain）。
        - 双重签名：在OEM签名的基础上，还允许由QTI进行签名（可选），将产生两套证书和证书链。两套签名都校验正确才通过。
        - 根证书是针对一个HASH值进行校验的，HASH值要么存在QFPROM eFuses中，要么保存在硬件ROM代码中。（见[Refer[3]](https://www.notion.so/Things-About-QSEE-On-Mobile-d705c73739c241e48aab6765102a11b3?pvs=21)）
- 高通的SDK中有一个名为sectools的工具来做签名和文件分解，在网上找到[一份](https://gitlab.mingwork.com/hanguoliang/test/tree/8e3a790f3a19335c80e72fab48245550233323db/adsp_proc/sectools)。
- 使用[https://github.com/pandasauce/unify_trustlet](https://github.com/pandasauce/unify_trustlet) 这个工具可以将这些零散的文件合并：
    - 工具原理是：读取ProgramHeaders，然后按照Segment的序号，依次读取.bXX文件拼接到文件内正确的位置。

### libQSEEComAPI.so分析

- 闭源，但是AOSP中有一份头文件[QSEEComAPI.h](https://cs.android.com/android/platform/superproject/+/master:hardware/qcom/keymaster/QSEEComAPI.h)
- 通过/dev/qseecom字符设备与内核通信，内核侧源码：
    - [/drivers/misc/qseecom.c](https://android.googlesource.com/kernel/msm.git/+/refs/tags/android-12.0.0_r0.7/drivers/misc/qseecom.c)
    - [/include/uapi/linux/qseecom.h](https://android.googlesource.com/kernel/msm.git/+/refs/tags/android-12.0.0_r0.7/include/uapi/linux/qseecom.h)
- IDA分析
    - QSEECom_start_app(): 存在v1和v2两个版本
        - `QSEECom_start_app()`: 传入trustlet文件路径，读取`*.md`t、`*.bXX`，将所有文件直接拼接在一起，然后写入到啊内存中传递给内核中的qseecom驱动 。加载完成后释放ION内存
        - `QSEECom_start_app_V2()`: 传入普通内存中加载好的trustlet文件buffer，拷贝到ION内存中，传递给内核中的qseecom驱动。加载完成后释放ION内存
    - 其余函数未分析。。

## trustlet文件分析（以soter64）为例

![Untitled](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%2011.png)

### 证书链

- 三级证书模式：
    - 叶子证书是为每个trustlet单独生成的，比如alipay的和soter64的叶子证书不同。
    - 叶子证书中OU字段包含了trustlet的一些元数据如HW_ID、OEM_ID、APP_ID之类的，但文档说新的做法是将这些元数据移到ELF文件中而不是叶子证书上。

![某个trustlet特定的证书](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%2012.png)

某个trustlet特定的证书

![中间证书](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%2013.png)

中间证书

![根证书](/images/Things%20About%20QSEE%20On%20Mobile%20d705c73739c241e48aab6765102a11b3/Untitled%2014.png)

根证书

### 总结

下一步计划借助ida分析，但是存在一些难点
- 缺少函数定义头文件
- 似乎与GlobalPlatform组织的API标准不同