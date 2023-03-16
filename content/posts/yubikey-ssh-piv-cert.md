---
title: "使用Yubikey PIV和PKCS#11来验证SSH Client"
date: 2023-03-16T18:35:35+08:00
categories:
  - Security
tags:
  - Yubikey
  - PKCS11
draft: false
---

前段时间抽空给自己的“Homelab”服务器加了内存，能开更多的VM & Conteiner了。虽然用Tailscale和自建Headscale/Derper服务的方式组了内网，访问服务器上的服务的时候也都是走的内网，一定程度上通信链路上是安全了。但是目前还是一个ssh key到处用，如果笔记本失窃/密钥被读走了，还是很危险的，(说起来之前用Termius就是自动把`~/.ssh/`里的所有key都上云了)。所以这次借着升级配置的这个机会，把手里的Yubikey的PIV功能给用上，让ssh server能够用Yubikey里存的私钥来验证ssh client。

# 证书生成与导出

基本上是参考了Yubikey Handbook里的[Authenticating SSH with PIV and PKCS#11 (client)](https://ruimarinho.gitbooks.io/yubikey-handbook/content/ssh/authenticating-ssh-with-piv-and-pkcs11-client/)这篇文章，下面的内容也是基于这篇文章来说明。

1. 首先在yubikey中生成一对RSA 2048密钥，并生成一个自签名证书，这个可以选择用`yubico-piv-tool`命令行工具，也可以用`Yubikey Manager`这个GUI工具，我选择了后者。

    这里除了能够生成自签名证书，还可以选择生成CSR(certificate signing request)，我想应该是为了方便让CA签证书的场景。之前也考虑过自建CA的事，不过感觉麻烦就搁置了。

2. 从证书中导出公钥，保存到`~/.ssh/ybk_piv.pub`里(文件名任意)

    ```sh
    ssh-keygen -D /usr/lib/opensc-pkcs11.so -e > ~/.ssh/ybk_piv.pub
    ```

# 服务端配置

将该公钥安装到目标sshd服务器的`~/.ssh/authorized_keys`里

```sh
ssh-copy-id -f -i ~/.ssh/ybk_piv.pub <user>@<server-ip>
```

到此，服务端的配置就完成了

# 配置客户端环境

PKCS#11是一套为应用程序使用HSM执行密码函数而定义的API标准，也称为Cryptoki(Cryptographic token interface)。

[OpenSC](https://en.wikipedia.org/wiki/OpenSC)是PKCS#11的一个实现，而它可以使用[PC/SC](https://en.wikipedia.org/wiki/PC/SC)作为后端。后者是一种将智能卡集成到计算环境中的规范，在Linux上的实现者为[pcsclite](https://github.com/LudovicRousseau/PCSC)。[CCID](https://en.wikipedia.org/wiki/CCID_(protocol))是一种USB协议，Yubikey设备支持这种协议。

在一个新的Linux主机上，要让ssh client使用PKCS#11来验证，至少需要准备以下软件组件，以ArchLinux环境为例

  1. 安装`pcsclite`并确保`pcscd.service`正在运行
  2. 安装`opensc`，这时你将拥有`/usr/lib/opensc-pkcs11.so`和`pkcs11-tool`
  3. 安装`ccid`

这时运行`pkcs11-tool -L`你应该能看到你的Yubikey并且其中有一个solt。

```txt
➜  ~ pkcs11-tool -L   
Available slots:
Slot 0 (0x0): Yubico YubiKey OTP+FIDO+CCID 00 00
  token label        : ssh
  token manufacturer : piv_II
  token model        : PKCS#15 emulated
  token flags        : login required, rng, token initialized, PIN initialized
  hardware version   : 0.0
  firmware version   : 0.0
  serial num         : xxxxxxxxxxxxxxxx
  pin min/max        : 4/8
```

如果没有，请排查上述服务/软件包，并检查lsusb和udev配置。

# 配置客户端openssh client

遗憾的是支持PKCS#11密钥的ssh client并不多，实测Termius并没有此功能，但是看介绍xshell好像支持的。但是一般来说咱们也就用openssl client了所以这里以它为例。

这里有两种选择，一种是在每次开机后用`ssh-add`主动将密钥添加到ssh-agent里

```sh
ssh-add -s /usr/lib/opensc-pkcs11.so
```

优点是只需要在添加的时候输入一次PIN码，之后（注销之前）再插拔yubikey不需要再次输入。（为啥我觉得这不算是什么优点反而是缺点）


另一种则是在`~/.ssh/config`里配置`PKCS11Provider`。比如下面的配置给所有的Host在登陆时都尝试使用yubikey上的密钥

```txt
Host *
	PKCS11Provider /usr/lib/opensc-pkcs11.so
```
在这种配置下在每次ssh登陆的时候都会让你输一次PIN码（~~是不是感觉安全了很多？~~ 其实并不，如果输过一次了只要按一下回车就可以过，除非拔掉yubikey再插才会再问你要密码）

# 和`IdentitiesOnly yes`一起使用

一般来说咱们还是习惯给不同的服务器配置不同的密钥的，这也导致我们在`~/.ssh/`里会有一大坨密钥。ssh-agent也会悉数将其收入，然后在连接ssh server的时候挨个尝试，结果就导致`Too many authentication failures`出现， 所以openssh提供了`IdentitiesOnly yes`这个配置避免这个问题，在这种情况下对于`~/.ssh/config`里的每个Host，只会尝试由`IdentityFile`指定的key。如果这个Host没有指定的话就尝试`~/.ssh/id_rsa`之类的默认密钥路径。

但是openssl在处理的时候似乎有一点bug，当`IdentitiesOnly yes`和`PKCS11Provider`同时存在时，后者会被忽略。根据[这里](https://groups.google.com/g/opensshunixdev/c/jD1pghvajpo)的讨论，`IdentityFile`相当于一个filter，只会尝试`IdentityFile`指定的那些公钥， 因此一个解决办法是加一个`IdentityFile`指向我们之前从yubikey里导出的公钥，完整例子如下：

```txt
Host *
	IdentitiesOnly yes
	PKCS11Provider /usr/lib/opensc-pkcs11.so
	IdentityFile ~/.ssh/ybk_piv.pub
```

# 闲聊

其实不管是普通的ssh密钥文件还是这篇文章中提到的PIV，都是对ssh client侧的验证。那么对ssh server侧的验证又如何呢？

在ssh client第一次连接到一个新的ssh server时，会显示server侧公钥的`fingerprint`，并且问你：
```txt
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```
这时候如果你信任这个网络环境，或者你比对过这个fingerprint是对的，你可以直接yes，然后它会把server的公钥加到`~/.ssh/known_hosts`里面。或者你可以输入一个指纹比如`SHA256:CB5smnwKhpcnT1bz6OXHYuFcijlMS3nw2tEJ2HoR++A`之类的，接着它会帮你比对。当之后你连接到server时，如果这时发生了中间人攻击，那么ssh client能够根据`~/.ssh/known_hosts`中的公钥比对失败来检测到。这就是所谓的[Trust on first use (TOFU)](https://en.wikipedia.org/wiki/Trust_on_first_use)的方式。

所以（在最常见的配置情况下）对ssh server的验证关键在第一次连接时。ssh client把责任交给了用户，它假设你能够根据额外的可信信息源来确认这个fingerprint（因为第一次连接的时候没有信任锚，之后的信任锚在`~/.ssh/known_hosts`里）。

但是在大多数情况下，我们忽略了这一步，直接yes掉。假设一个足够强大的攻击者（比如所在单位的网络管理员、运营商级、~~甚至country级~~的劫持），能够在你第一次连接这个服务器时就篡改你的数据包做MITM攻击，并且对于之后的连接都能够劫持并篡改（防止因为fingerprint变动而被受害者察觉到MITM的存在），那如果你没有手动和server上的fingerprint比对，至始至终你的ssh会话都是透明的。

到这里，是不是感觉ssh其实也没有那么的安全，毕竟你大概率也没有真正比对过你~~海外的某台VPS~~服务器上的fingerprint对吧（笑）。如果你想现在做一下验证，[这篇文章](https://www.phcomp.co.uk/Tutorials/Unix-And-Linux/ssh-check-server-fingerprint.html)里提到了在server端计算fingerprint的几个命令，你可以用它来和ssh连接时的指纹进行比对。最好经过可信的方式登陆到服务器并运行这些命令，如经过云服务商的VNC控制台/更为可信的网络环境/隧道/`ssh -J`等，以防御对终端输出内容进行匹配替换的攻击者（不过真的有人会这么做吗）。

突然想到，整个世界好像就是在“各式各样的草台班子”和“自欺欺人般的信任”中运转的。

完。
