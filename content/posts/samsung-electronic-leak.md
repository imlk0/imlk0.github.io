---
title: "Samsung Electronic 泄漏源码内容分析"
date: 2022-03-12T08:32:24+08:00
categories:
  - TEE
tags:
  - TrustZone
  - Security
  - Leak
draft: false
---

# Samsung Electronic - part 1

## BootLoader

三星系列手机的bootloader，带源码

![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled.png)

## TrustedAPPs

- 带源码
    - 一套源码适配三种TA系统
        - QSEE - 高通
        - Kinibi - Trustonic （也称T-Base或Mobicore，主要用于Mediatek和ExynosSoC）
        - teegris - 三星
        
        ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%201.png)
        
- 包含的TA和国产厂商如一加内置的TA种类很不一样，仅个别重复出现
    - 泄露的TA应用列表
        
        Activation
        Arcounter
        Attestation
        AUTHHAT
        BioAuthDriver
        bksecapp
        BLGRD
        DDAR
        DeviceRootKey
        DSMS
        engmode
        esecomm
        FIVE
        GATEKEEPER
        HDCP
        HDM
        ICCC
        ifbio
        KG
        KnoxAIFac
        mPOS
        MST
        MZ
        PROCA
        QUESTAPP
        SecFace
        SecFinger
        SEM
        skeymaster_swd
        SKPM
        smartfitting
        softsim
        spi_csmc_handler
        SSU
        Tadownloader
        tigerfp
        tima_csmc_handler
        TimaDriver
        TimaKeystore
        TUI
        VaultKeeper
        Widevine
        WSM
        
    - 一加6内置TA
        
        adsp
        alipay
        cdsp
        cmnlib64
        cmnlib
        cpe_9340
        cppf
        dhsecapp
        dxhdcp2
        esesvc
        faceapp
        fpc1228
        gfp5288
        gfp9508
        gpqese
        gptest
        haventkn
        modem
        securemm
        sl7000
        slpi
        soter64
        venus
        voicepri
        widevine
        

## 其他有价值的东西

- Samsung Electronic - part 1/PR/1716/CONFIDENTIAL/TRUSTEDAPPS/TOOLS/
    - 这里面有若干个签名工具（多是.jar文件）
        
        ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%202.png)
        
        ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%203.png)
        
    - 以及众多makefile文件
        
        ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%204.png)
        
    - 若干个私钥
        - Samsung Electronic - part 1/PR/1716/CONFIDENTIAL/TRUSTEDAPPS/TOOLS/multibuild/tools/sign-apk/
            
            ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%205.png)
            
        - [https://sizeof.cat/post/samsung-electronics-leak/](https://sizeof.cat/post/samsung-electronics-leak/)
    - 为不同的TEEOS实现了global platform 定义的标准API兼容层
        - Samsung Electronic - part 1/PR/1716/CONFIDENTIAL/TRUSTEDAPPS/TOOLS/multibuild/source/gp-api/tee/qsee
            
            ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%206.png)
            

# Samsung Electronic - part 2

未看

> Part 2 contains a dump of source code and related data about device security and encryption related stuffs.
> 

# Samsung Electronic - part 3

> Part 3 contains various repositorys from Samsung Github. Including Mobile defense engineering, Samsung account backend, Samsung pass backend/frontend, and SES (Bixby, Smartthings, store, etc)
> 

来自私有github仓库的内容

- PartEmu源码
    
    ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%207.png)
    
    ![Untitled](/images/Samsung%20Electronic%20-%20%E5%86%85%E5%AE%B9%E5%88%86%E6%9E%90%20f8087a6afc024bd99475b1908c9f07a3/Untitled%208.png)
    

## syzkaller

两个目录下存在syzkaller

- Github/srpol-sruk-sec/syzkaller/（较新，Mon Jun 28 18:20:38 2021）
- Github/co7-srpol-mobile-security/syzkaller/

与原版存在的主要区别是:

- sys/models/
    - 此目录下放置了对多台samsung设备fuzz的配置json文件以及syzkaller描述文件，但疑似为批量生成。
    - 其中对于qseecom的fuzz描述文件和我之前第一次产生的类似，均没有描述到TA加载过程（很难fuzz到TA加载相关的内容）
- README.md
    - 此文件列出了受支持的设备列表