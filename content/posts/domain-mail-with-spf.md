---
title: "使用SPF来保护你的域名邮箱"
date: 2022-01-18T13:04:37+08:00
categories:
  - Security
tags:
  - SPF
  - DNS
  - Mail
---



今天翻看邮箱，偶然看到之前课程助教让我们做作业时使用S/MIME签名和加密的邮件，然后想起邮件系统的设计似乎可以轻松伪造Sender这一问题，结果就看到一个叫SPF的东西，遂把它配置到自己的域名邮箱上，记录一下。

## 何为SPF

> 发件人策略框架（英语：Sender Policy Framework；简称SPF； RFC 4408）是一套电子邮件认证机制，可以确认电子邮件确实是由网域授权的邮件服务器寄出，防止有人伪冒身份网络钓鱼或寄出垃圾电邮。SPF允许管理员设定一个DNS TXT记录或SPF记录设定发送邮件服务器的IP范围，如有任何邮件并非从上述指明授权的IP地址寄出，则很可能该邮件并非确实由真正的寄件者寄出（邮件上声称的“寄件者”为假冒）
>
> *From：[Wikipedia-发件人策略框架](https://zh.wikipedia.org/wiki/%E5%8F%91%E4%BB%B6%E4%BA%BA%E7%AD%96%E7%95%A5%E6%A1%86%E6%9E%B6)*

简单来说，就是发送方可以在自己域名的TXT字段上配置一些允许的ip地址范围，只有在这些ip地址发出的邮件才被认为是真实的。如果其它ip的主机以这个域名下的邮箱身份发出邮件，接收者可以认为邮件是假冒的。

（算是又一个基于DNS来保证安全的例子了）

拿我们常用的gmail为例，查询`google.com`的TXT记录，其中一个结果就是SPF配置：

```
google.com.             19      IN      TXT     "v=spf1 include:_spf.google.com ~all"
```

qq邮箱和163邮箱也是类似：

```
qq.com.                 97      IN      TXT     "v=spf1 include:spf.mail.qq.com -all"
```

```
163.com.                10295   IN      TXT     "v=spf1 include:spf.163.com -all"
```

这三个邮箱都没有直接列出允许的ip范围，而是使用了`include:<domain>`的形式来表示引入`<domain>`这个域名下的SPF记录（用法有点像CNAME那样）。

关于spf的更多语法，建议阅读[这篇文章](https://www.renfei.org/blog/introduction-to-spf.html)。

## 如何配置

本人的域名邮箱接的是腾讯企业邮，[其网站](https://service.exmail.qq.com/cgi-bin/help?subtype=1&id=20012&no=1000580)上其实有介绍该怎么配置。

具体来说，只要为你邮箱中的域名加上下面这样一条TXT记录就行了：

```
v=spf1 include:spf.mail.qq.com ~all
```

最后效果是：

```
imlk.top.               300     IN      TXT     "v=spf1 include:spf.mail.qq.com ~all"
```

对于自建邮箱服务器的情况，按规则自己写一条包含ip的spf就行了。

## 补充

### DKIM

DKIM是一种防止邮件内容被恶意篡改的方法，发件服务器使用私钥为邮件进行签名，而接收方通过dns查询到发件方域名对应的公钥信息，验证签名的完整性。

可惜的是**腾讯企业邮箱似乎无法开启DKIM**，默认发出去的邮件中也未找到`DKIM-Signature`字段。

![image-20220118152416029](/images/image-20220118152416029.png)

### DMARC

如果说SPF和DKIM定义了如何防止被别人假冒身份发送邮件，那么DMARC则定义了接收者收到假冒邮件后应该怎么处理。

给域名下的`_dmarc`子域加一条TXT记录`v=DMARC1; p=none; rua=mailto:mailauth-reports@qq.com`，具体细节可以直接[参考](https://service.exmail.qq.com/cgi-bin/help?subtype=1&no=1001520&id=16)腾讯企业邮箱。

## 测试SPF

[这个网站](https://www.appmaildev.com/cn/spf)可以直接测试SPF：

具体来说，它会随机生成一个邮箱，然后让你用配置好spf的邮箱给它发邮件，然后会出一份报告。

![image-20220118133534557](/images/image-20220118133534557.png)

看起来配置没有问题。

接着我们使用[swaks](https://www.jetmore.org/john/code/swaks/)从本机直接发送一封伪装身份的邮件：

```
swaks --to test-e16ba1a8@appmaildev.com --from me@imlk.top --body 'This is a spoof email' --header 'Subject: Spoof Email' --ehlo imlk.top --header-X-Mailer imlk.top
```

结果SPF检测报告SoftFail

![image-20220118153014062](/images/image-20220118153014062.png)

并且DMARC也报告了fail

![image-20220118153031854](/images/image-20220118153031854.png)

如果向Gmail发送伪装身份的文件，则会报告错误：

![image-20220118153207011](/images/image-20220118153207011.png)

## 参考

- [SPF 测试工具](https://www.appmaildev.com/cn/spf)

- [邮件伪造原理和实践 -  SAUCERMAN](https://saucer-man.com/information_security/452.html)
- [腾讯企业邮箱 - 帮助中心 - 设置企业邮箱的DMARC](https://service.exmail.qq.com/cgi-bin/help?subtype=1&&no=1001520&&id=16)
- [腾讯企业邮箱 - 帮助中心 - 设置企业邮箱的SPF](https://service.exmail.qq.com/cgi-bin/help?subtype=1&&no=1000580&&id=20012)
