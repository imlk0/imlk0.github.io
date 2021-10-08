---
title: 'Android11的QPR1安全更新后无法连接北邮校园WiFi的解决方法'
date: 2021-03-17 13:51:32
id: 70
categories:
    - [misc]
tags:
    - [BUPT]
    - [wpa2-enterprise]
---

Android11在2020年12月发布的安全更新中进行了一个修复：[PSA: Android 11 will no longer let you insecurely connect to enterprise WiFi networks](https://www.xda-developers.com/android-11-break-enterprise-wifi-connection/)

这项变更直接导致的是连接安全性为`wpa2-enterprise`的WiFi时，去掉了`不验证(Do Not Validate) CA证书`的选项：![image-20210317140152847](/images/blog/70/image-20210317140152847-1615965848255.png)

## 802.1X

根据[维基百科](https://zh.wikipedia.org/wiki/IEEE_802.1X)，802.1X是一种关于用户接入网络的认证标准，它工作在二层，通过EAP协议（Extensible Authentication Protocol）进行认证，为`wpa-enterprise/wpa2-enterprise`提供了接入控制。BUPT的校园WiFi `BUPT-mobile`使用的就是这样的接入方式：

![image-20210317141740866](/images/blog/70/image-20210317141740866-1615965914316.png)

[EAP](https://zh.wikipedia.org/wiki/%E6%89%A9%E5%B1%95%E8%AE%A4%E8%AF%81%E5%8D%8F%E8%AE%AE)是一种可扩展的认证机制，通常使用的认证方法有EAP-TLS、EAP-TTLS、PEAP。前者是在服务端和客户端都会校验对方的证书。后两者则只需要服务器提供证书。

`BUPT-mobile`可以选择`TTLS`或者`PEAP`方法，再结合学生的上网账号密码连接。这种认证方式使用PKI机制来确保验证过程的安全性(服务器发来一个证书，客户端用证书中包含的公钥与服务器建立通信)，非常类似于浏览网页时建立TLS连接时的那样。

但是如何确保服务器发来的证书的真实性？这里有两个选择，一是向CA购买证书，另一种则是自建PKI系统，自己当CA，自己给自己发证书。

（像百邮这样"top secret"的，当然是选择后者啦23333）

因此，在ios设备上首次连接`BUPT-mobile`后，会弹出一个这样的：

![image-20210317145134096](/images/blog/70/image-20210317145134096.png)

由于是采用自建的PKI系统，所以签发这个证书的CA证书是没有被预装在我们设备里面的，因此这里提示的是这个证书**不可信**。

Android上没有这样的提示，因此一直以来，我们在连接的时候都必须要选择 **不验证** 服务器发来的证书：

![image-20210317142829088](/images/blog/70/image-20210317142829088.png)

## CA证书

在Android11之后，虽然没有了这个`不验证`的选项，我们还是有办法连接校园WiFi的。

思路也很简单，既然不信任学校的CA签发的证书，那我们把CA的证书安装到手机里，信任了CA证书，那么它签发的证书也就能够被信任了。

### 用wireshark抓取证书

前面提到EAP是二层协议，我们在建立WiFi连接的时候进行抓取：

![image-20210317150539106](/images/blog/70/image-20210317150539106.png)

可以看到上面编号为7的包里面有AP发来的证书：

![image-20210317150815374](/images/blog/70/image-20210317150815374.png)

解开发现包含了两个证书，我们右键将其保存下来（后缀名为.cer）：![image-20210317150918046](/images/blog/70/image-20210317150918046.png)

这两个证书一个身份是`BUPT Local Server Certificate`一个是`BUPT Local Certificate Authority`。前者由后者所颁发，而后者是一个自签名的证书。从名字来看，相信后者应该就是BUPT自制的CA证书了。

### 安装证书

将CA证书（后者）传到手机上，在文件管理器中点击打开，会弹出一个证书安装程序：

![image-20210317151645163](/images/blog/70/image-20210317151645163.png)

选择凭据用途为WLAN，然后给它起个名点击确认安装。

在WiFi连接时：EAP方法选择`TTLS`或者`PEAP`，CA证书选择刚刚我们安装的那个证书，域名留空（**如果必须要填域名的话，域名那里填`BUPT Local Server Certificate`**，即颁发的证书里的CN字段的值），身份和密码分别填写上网账号密码便可连接上了：

![image-20210317151810275](/images/blog/70/image-20210317151810275.png)

![image-20210317152000936](/images/blog/70/image-20210317152000936.png)

最后将证书文件放在这里：

- 证书: [cer1.cer](/objects/cer1.cer)

- CA证书: [cer2.cer](/objects/cer2.cer)

文件的md5sum:
```
3784d3f46879644a0d1343208f381005  cer1.cer
4b60d9eaa8eaf05f784391d9e83a1f34  cer2.cer
```

> 最后，由于在设备上随意安装未知来源的CA证书是一件很危险的事情，使用上面的证书文件的同时，也意味着您已经了解并明白潜在的风险，本人不承担由此导致的任何责任。


## refer

- [Wireless Encryption and Authentication Overview](https://documentation.meraki.com/MR/Encryption_and_Authentication/Wireless_Encryption_and_Authentication_Overview)

- [企业级无线渗透之PEAP](https://wooyun.js.org/drops/%E4%BC%81%E4%B8%9A%E7%BA%A7%E6%97%A0%E7%BA%BF%E6%B8%97%E9%80%8F%E4%B9%8BPEAP.html)