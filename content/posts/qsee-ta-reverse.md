---
title: "以逆向的方式分析QSEE TA中的组件"
date: 2021-11-26T16:11:58+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - QSEE
draft: false
---


# TA链接的组件

位于`trustzone_images/core/bsp/trustzone/qsapps/applib64/` （64bit）

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled.png)

其中两个`.o`文件被静态链接到每个TA里面，而`.lib`编译到cmnlib/cmnlib64里

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%201.png)

## tzapp_entry.so

被静态链接到每个TA里面

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%202.png)

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%203.png)

其中`TZAPPENTRYCODE`是一个特殊的section，其中包含入口点一个定义的符号`TZAPPENTRY`。

根据编译选项`-e TZAPPENTRY`，`TZAPPENTRY`是程序入口点。

### TZAPPENTRY

是一个薄层：

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%204.png)

调用`get_app_md(): applib64.lib/common_applib.o`: 指定了`CElfFile_invoke`作为`entry_addr`

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%205.png)

`app_export_init_info_to_qsee(): applib64.lib/tzapp_syscall.o`: 将app metadata通过系统调用传给qsee

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%206.png)

### get_cmnlib_ctx_ptr

`get_cmnlib_ctx_ptr()`: 从系统寄存器`[TPIDRRO_EL0](https://developer.arm.com/documentation/ddi0595/2021-03/AArch64-Registers/TPIDRRO-EL0--EL0-Read-Only-Software-Thread-ID-Register)`中读得cmnlib_ctx的地址

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%207.png)

## **tzapp_lib_main.o**

![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%208.png)

## applib32.lib / applib64.lib

是静态库文件，包含121个`.o`文件，

- 已知.o文件列表
    
    abort.o
    bn_add.o
    bn_asm.o
    bn_ctx2.o
    bn_div.o
    bn_exp.o
    bn_gcd.o
    bn_kron.o
    bn_lib.o
    bn_malloc2.o
    bn_mod2.o
    bn_mont.o
    bn_mul.o
    bn_prime.o
    bn_prime_tbl.o
    bn_print.o
    bn_rand.o
    bn_recp.o
    bn_shift.o
    bn_sqr.o
    bn_sqrt.o
    bn_word.o
    clock.o
    common_applib.o
    gpFileService.o
    gpList.o
    gpPersistentObjects.o
    gpPersistObjCommon.o
    gpPersistObjCrypto.o
    gpPersistObjData.o
    gpPersistObjFileIO.o
    gpPersistObjHandler.o
    gpPersistObjIndex.o
    gpPersistObjVersion.o
    isaac_rand.o
    kthread_shared.o
    libstd_std_scanul.o
    memchr.o
    memcmp.o
    memcpy.o
    memmove.o
    memrchr.o
    memscpy.o
    memset.o
    memsmove.o
    mink_shared_code.o
    printf.o
    prxy_ecc.o
    prxy_qsee_shim.o
    prxy_secmath.o
    prxy_secrsa.o
    prxy_services.o
    prxy_ufaes.o
    prxy_ufdes.o
    prxy_ufsha.o
    qbn_xbgcd.o
    qsee_appmessage.o
    qsee_boot_shim.o
    qsee_bulletin_board_shim.o
    qsee_cfg_prop_shim.o
    qsee_cipher.o
    qsee_cmac.o
    qsee_comstr.o
    qsee_core_shim.o
    qsee_counter_shim.o
    qsee_crypto_shim.o
    qsee_dcache.o
    qsee_deviceid.o
    qsee_env.o
    qsee_ese_service.o
    qsee_hash.o
    qsee_hmac.o
    qsee_hw_fuse.o
    qsee_i2c.o
    qsee_intmask.o
    qsee_int_shim.o
    qsee_keyprov.o
    qsee_km_shim.o
    qsee_nsmem.o
    qsee_oem_buffer.o
    qsee_prng.o
    qsee_sec_camera.o
    qsee_secdisp.o
    qsee_secure_channel.o
    qsee_shared_buffer.o
    qsee_spcom.o
    qsee_spi.o
    qsee_sync.o
    qsee_timer_shim.o
    qsee_tlmm.o
    qsee_trans_ns_addr.o
    qsort.o
    rand_lib2.o
    secure_memset_dword.o
    secure_memset.o
    sfs_api.o
    stor_gpt.o
    stor.o
    stor_rpmbw.o
    strcasecmp.o
    strchrnul.o
    strchr.o
    strcmp.o
    strlcat.o
    strlcpy.o
    strlen.o
    strncasecmp.o
    strncmp.o
    strnlen.o
    strrchr.o
    strstr.o
    timesafe_memcmp.o
    timesafe_strncmp.o
    tzapp_syscall.o
    wcslcat.o
    wcslcpy.o
    wstrcmp.o
    wstrlcat.o
    wstrlcpy.o
    wstrlen.o
    wstrncmp.o
    

重要的部分：

- common_applib.o
- tzapp_syscall.o

## metadata.c

在编译前生成metadata.c，包含TA的元数据，参与链接。

脚本位置：trustzone_images/core/bsp/build/scripts/secure_apps.py

metadata.c大致内容

```c
const char __attribute__((section(".rodata.sentinel"))) TA_METADATA[] = %s;
const char* TA_APP_NAME = "%s";
const unsigned char TA_UUID[] = { 0x%s, 0x%s, 0x%s, 0x%s,
                                  0x%s, 0x%s, 0x%s, 0x%s,
                                  0x%s, 0x%s, 0x%s, 0x%s,
                                  0x%s, 0x%s, 0x%s, 0x%s };
const unsigned int TA_ACCEPT_BUF_SIZE = %s;
char ta_acceptBuf[%s] = {0};
const bool ta_multiSession = %s;
const char * ta_version = "%s";
const char * ta_description = "%s";
const struct TACustomProperty {
   char const * name;
   char const * value;
} ta_customProperties[] = {}
const unsigned int TA_CUSTOM_PROPERTIES_NUM = %s;
```

# TZAPP生命周期

- void tz_app_init(void)
    
    调用链：
    
    ```c
    int32_t __fastcall CElfFile_invoke(ObjectCxt h, ObjectOp op, ObjectArg_0 *a, ObjectCounts k); // applib64.lib/common_applib.o
    void __fastcall tzlib_app_entry(void *ctz_lib_entry); // applib64.lib/common_applib.o
    int __cdecl secure_app_init(); // tzapp_lib_main.o
    void tz_app_init(void); // TZAPP
    ```
    
    `CElfFile_invoke()` 在`get_app_md()`中指定
    
- void tz_app_shutdown(void)
    
    调用链：
    
    ```c
    int32_t __fastcall AppModule_invoke(ObjectCxt h, ObjectOp op, ObjectArg_0 *a, ObjectCounts k); // applib64.lib/common_applib.o
    int __cdecl secure_app_shutdown(); // tzapp_lib_main.o
    void tz_app_shutdown(void); // TZAPP
    ```
    
    `AppModule_invoke()`在`CElfFile_invoke()`中指定
    
    ![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%209.png)
    
- void tz_app_cmd_handler(void* cmd, uint32 cmdlen, void* rsp, uint32 rsplen)
    
    其中`cmd`和`rsp`指向的内容是TA自定义的，通常是结构体
    
    调用链：
    
    ```c
    int32_t __fastcall CApp_invoke(ObjectCxt h, ObjectOp op, ObjectArg_0 *a, ObjectCounts k); // tzapp_lib_main.o
    int32_t __fastcall CApp_handleRequest(void *cxt, int32_t commandID, uint64_t reqAddr, uint64_t reqSize, uint64_t respAddr, uint64_t respSize); // tzapp_lib_main.o
    void tz_app_cmd_handler(void* cmd, uint32 cmdlen, void* rsp, uint32 rsplen); // TZAPP
    ```
    
    `CApp_invoke()`在`AppModule_invoke()`中指定
    
    ![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%2010.png)
    

# API

大致有以下几类

- 密码学：hmac,  ecc, rsa, hash, prng
- 文件系统访问：open, read, write, mkdir... / 安全文件系统访问(加密): qsee_sfs_open()
- 内存管理: qsee_malloc, qsee_free
- 安全存储: fuse,  qsee_stor
- 外设访问：i2c, spi, sec_camera
- 日志: qsee_log
- 通信：TA间、TA和Client间
- 其它：Secure UI ...

# soter64

- cmd_id：将`void* cmd`的前4个字节解释成`int cmd_id`，共定义了15个cmd_id，32bit值，范围`0x0000011 - 0x000001f`
    
    ![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%2011.png)
    

> [https://github.com/Tencent/soter/wiki/原理](https://github.com/Tencent/soter/wiki/%E5%8E%9F%E7%90%86): TENCENT SOTER中，一共有三个级别的密钥：ATTK，App Secure Key(ASK)以及AuthKey。这些密钥都是RSA-2048的非对称密钥。
> 
- 每个cmd_id对应各自的handler
    
    ![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%2012.png)
    
    例如第三个功能`SOTER_EXPORT_ATTK_PUBLIC`：
    
    ![Untitled](/images/QSEE%EF%BC%9ATA%20e9418bc03ef745e0ab9a5990d86c812b/Untitled%2013.png)
    

# 一些额外的知识

## arm64 sysregs

 使用`msr`和`mrs`指令读写系统寄存器，具体寄存器的编号用`S<op0><op1>_C<CRn>_C<CRm0><op2>`格式表示。在ARM32中是使用协处理器和`mrc`和`mcr`来处理的。

- [https://developer.arm.com/documentation/den0024/a/ARMv8-Registers/System-registers](https://developer.arm.com/documentation/den0024/a/ARMv8-Registers/System-registers)
- https://aijishu.com/a/1060000000119041