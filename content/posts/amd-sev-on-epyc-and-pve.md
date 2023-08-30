---
title: "探究AMD SEV/SEV-ES远程证明过程——在EPYC 7302洋垃圾服务器上"
date: 2023-04-14T13:00:31+08:00
categories:
  - TEE
tags:
  - SEV
  - KVM
  - Homelab
  - Security
draft: false
---

去年把Homelab升级到了EPYC 7302，是二代的EPYC产品，代号"rome"，这块CPU支持SEV和SEV-ES特性也就是所谓机密虚拟机。Intel的CPU中与之对应的则是TDX，只可惜支持TDX特性的CPU价格昂贵，是难以触碰到的。与之相比，AMD SEV系列则比较容易买到，花费千元不到的价格，就能买到二代EPYC。目前支持SEV-SNP的三代EPYC的二手价格最低是3500左右，还是略高。

在本文中，我将通过实验如何创建一个SEV/SEV-ES虚拟机、对虚拟机进行度量和secret注入，来学习和理解其远程证明过程。

> 本文仅限于对SEV/SEV-ES特性的简单尝试，和对pre-attestation远程证明的理解。这篇文章中的许多部分，尤其是Guest VM中OVMF、GRUB、Kernel、Kernel cmdline的配置和度量并不完备，**请勿直接将文中的命令直接用于构建生产环境**，而是使用现有的成熟方案，例如[confidential-containers/kata-containers-CCv0](https://github.com/confidential-containers/kata-containers-CCv0)。

## Host环境配置

Host环境比较好配，libvirt有一篇[文章](https://libvirt.org/kbase/launch_security_sev.html#id2)介绍了配置过程。

1. 开启SME：kernel cmdline 加`mem_encrypt=on`
2. 开启SEV：kernel cmdline 加`kvm_amd.sev=1`，给kvm_amd内核模块的sev参数。如果你想用SEV-ES，请加上`kvm_amd.sev_es=1`
3. BIOS配置：如果想要SEV-ES支持，需要在BIOS里，将`SEV-ES ASID Space Limit`从默认值1改成大一些的值。小于这个Limit值的ASID都将分配给SEV-ES，其余的分配给SEV。
![](/images/iKVM_capture_1.jpg)
![](/images/iKVM_capture_2.jpg)

最后，检查`/proc/cpuinfo`里有`sme`和`sev`，并且`/sys/module/kvm_amd/parameters/sev`的值为`Y`或者`1`就行了。如果是SEV-ES，还要检查`/proc/cpuinfo`里有`sev_es`，并且`/sys/module/kvm_amd/parameters/sev_es`的值为`Y`或者`1`

> 如果没有，记得检查一下你的CPU是否支持sev，并且BIOS里面是否开了SME支持（据说超微早期的一些BIOS没有这个选项）

dmesg里也会显示一些信息：
![](/images/2023-04-18-11-33-03.png)

## 创建和启动Guest VM

上面那篇文章也介绍了虚拟机的创建过程，包括建议使用Q35和OVMF等等。不过因为PVE和libvirt是冲突的，上面的配置方法不适用于我的环境：

- 对于`VM Configuration`章节的内容，我们可以按这些指引在PVE的WEB面板上找到对应的配置来创建虚拟机。（为了实验简单，我这里并未完全遵守其中的过程，而是clone了一台已有的Linux虚机来运行）

- 而对于`Checking SEV support in the virt stack`章节，鉴于PVE的Guest VM并没有提供SEV相关的配置，我们只能在qemu命令行参数上做手脚。

首先，在pve host上，使用`qm showcmd`查看创建的Guest VM的qemu启动命令

```sh
qm showcmd <vmid> --pretty 
```

把`<vmid>`替换成你的vm id

> 在pve上，`/usr/bin/kvm`是`qemu-system-x86_64`的一个符号链接

增加两个命令行选项
```txt
  -object 'sev-guest,id=sev0,cbitpos=47,reduced-phys-bits=1,policy=0x5' \
  -machine 'memory-encryption=sev0'
```

> 根据PVE的[文档](https://pve.proxmox.com/wiki/Manual:_qm.conf)，也可以通过PVE的虚拟机配置文件中的`args`参数来追加qemu命令行选项。

如果是SEV，需要设置`policy=0x1`，如果是SEV-ES，设置`policy=0x5`。具体的含义可以从 [AMD Secure Encrypted Virtualization API](https://www.amd.com/system/files/TechDocs/55766_SEV-KM_API_Specification.pdf) 的`Table 2. Guest Policy Structure`里找到如下描述：

![](/images/2023-04-17-15-34-39.png)

随后执行完整的qemu命令开启Guest VM。

> 如果你遇到`kvm: sev_kvm_init: failed to initialize ret=-25 fw_error=0 ''`，说明你的环境有问题，请参照`Host环境配置`章节进行检查。

在Guest VM中使用以下命令验证sev已经开启

```sh
dmesg | grep -i sev
```
![](/images/2023-04-18-14-17-08.png)

如果设置`policy=0x1`那就是：

![](/images/2023-04-14-14-50-57.png)

## SEV & SEV-ES的远程证明过程

SEV和SEV-ES只支持`pre-attestation`形式的验证，即在VM启动时进行度量和secret植入，而从epyc 7003系列开始增加的SEV-SNP特性支持`runtime-attestation`。由于作者只有epyc 7302的机器（买不起新的），本文只介绍`pre-attestation`。具体的流程可以参考[sev-tool](https://github.com/AMDESE/sev-tool#proposed-provisioning-steps)的文档，以及[AMD Secure Encrypted Virtualization API](https://www.amd.com/system/files/TechDocs/55766_SEV-KM_API_Specification.pdf)的「Appendix A Usage Flows」章节里的流程图，两者都算很清晰的。

本文将用virtee社区构建的[sevctl](https://github.com/virtee/sevctl)工具实际操作一遍这个过程，有助于对`pre-attestation`的理解。

> 至于为什么用sevctl不用AMD自己的sev-tool，因为我是rustacean :)

### 概念介绍

SEV的威胁模型想必不用多解释，这里介绍一下在这个实验中的三方：

- SEV Host (😈️): 或称平台Platform，指SEV的主机环境，包括Hypervisor，归属于平台所有者（服务器的提供者），并可以由其控制。在我们的实验中就是我的pve主机。
- SEV Guest VM (🤔): 受保护的机密容器，也就是托管在服务器上的的一个虚拟机，其安全性对于Guest Owner来说是未知的，需要通过remote attestation来证明。在实验中这是我在pve上的一个虚拟机。
- Relying Party (😇): 天然可以被Guest Owner所相信的一些环境。在实验中这个是我的个人电脑。

### 构建带SEV支持的OVMF

会发现pve自带的OVMF firmware是不支持AMDSEV的，使用该firmware我们将无法完成SEV的LAUNCH_SECRET环节。

参考了以下文档之后：
- [CCv0 with AMD SEV - confidential-containers社区](https://github.com/confidential-containers/documentation/blob/9faf24a7f26053820bd0c8a809134b2e8ed52d2d/demos/sev-demo/README.md#ovmf)
- [Getting Started with EDK II](https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II)

我决定自己构建OVMF firmware：

1. 通过包管理器安装`nasm`、`iasl`命令

2. 获取EDK2源码并编译OVMF
    ```sh
    git clone https://github.com/tianocore/edk2.git
    cd edk2 
    git submodule init
    git submodule update

    make -C BaseTools/
    source edksetup.sh

    touch OvmfPkg/AmdSev/Grub/grub.efi

    build -t GCC5 -a X64 -p OvmfPkg/AmdSev/AmdSevX64.dsc
    ```

产物路径为`Build/AmdSev/DEBUG_GCC5/FV/OVMF.fd`

### 构建sevctl

非常简单，clone下来然后cargo build就行啦

需要注意的是，对于`pre-attestation`，只需要在SEV Host，和Relying Party环境中编译和使用这个工具。不需要在SEV VM里编译它。

```sh
git clone https://github.com/virtee/sevctl
cd sevctl
cargo install --path .
```

### （平台）导出证书链

首先，需要在SEV Host上导出该平台PDH公钥及其证书链，并将其发给Guest Owner进行验证。

```sh
sevctl export /tmp/sev.pdh
```

使用scp将/tmp/sev.pdh拷贝到Relying Party侧

### （Relying Party）验证证书链完整性

```sh
sevctl verify --sev /tmp/sev.pdh
```
输出如下
```txt
PDH EP384 D256 6a8d620717a742dd522b914d5e730eb84eda5bcb47a57f46ce2b7e10f1901b13
 ⬑ PEK EP384 E256 ded12636fe3fdfe5774944ea91e475c1ddf1a1d9f1955469d784782d5989ae9b
   •⬑ OCA EP384 E256 63b5d98d309ce7c7b8c8a0f2ec93516560e0c4a5ef4535da0cbddd0f1e34e130
    ⬑ CEK EP384 E256 1345efa44c7a85979b07053ae5c5e16a0b103fc5bf3d0281b2f1ff8802ad71e6
       ⬑ ASK R4096 R384 d8cd9d1798c311c96e009a91552f17b4ddc4886a064ec933697734965b9ab29db803c79604e2725658f0861bfaf09ad4
         •⬑ ARK R4096 R384 3d2c1157c29ef7bd4207fc0c8b08db080e579ceba267f8c93bec8dce73f5a5e2e60d959ac37ea82176c1a0c61ae203ed

 • = self signed, ⬑ = signs, •̷ = invalid self sign, ⬑̸ = invalid signs
```

sevctl这个工具做的还是很精心的，证书链的可视化也很好，可以看到整个链上没有invalid的部分，这说明证书链是完好的。

这里简单解释一下每个密钥的用途：

平台部分：
- CEK(Chip Endorsement Key)：每个SEV平台，具体来说是一块CPU的唯一的密钥，它从烧录在CPU的OTP fuses里的一段secret派生而来，并不直接使用，用于给其它密钥签名。
- PEK(Platform Endorsement Key)：随机产生的ECDSA签名密钥，当该平台的所有者变更时重新生成。
- PDH(Platform Diffie-Hellman Key)：随机产生的ECDH密钥，是整个证书链的最末端。其生命期和PEK一样，**并非特定于某个Guest VM**的。它的用途后面会讲到

AMD部分：
- ASK(AMD Signing Key)：AMD持有，在出厂前对CEK进行签名
- ARK(AMD Root Key)：AMD持有，用于签署ASK

通过这条链，AMD向你证明这个平台是AMD认可的。

> 每一代EPYC产品的ASK/ARK证书可以从[AMD的网页](https://www.amd.com/en/developer/sev.html)上获得。
> 
> 每一块CPU对应的CEK也可以从[这个网页](https://kdsintf.amd.com/cek/)获得，参数cpu的标识id可以通过`sevctl show identifier`命令获得。注意每次访问时获得的CEK证书都是不同的（签名字段会变化）。

> 值得一提的是，由于CEK是从fuse派生的，AMD其实也是持有CEK的私钥部分的，这意味着在这条链上，你需要完全相信AMD。

以上是与AMD关联的一条链，细心的读者应该发现了从OCA开始的另一条链，`OCA->PEK->PDH`。
- OCA(Owner Certificate Authority Signing Key)：所有者持有的签名密钥。
可以看到，在证书链的位置上，OCA是与CEK并列的。通过这条链，还额外证明了这个平台是被某个平台所有者所拥有的。

具体来说这里还可以细分到两种模式：
1. self-owned：SEV firmware同时持有OCA公钥和私钥部分，它在内部生成这对密钥。这意味着任何一个外部实体都无法访问私钥。
2. platform-owned: SEV firmware只持有OCA公钥，而私钥由平台的所有者持有。

关于ARK和OCA两个证书链，这里有一个很好的说明：https://github.com/inclavare-containers/attestation-evidence-broker/blob/master/docs/design/design.md#sev-es-attestation-evidence

### （Relying Party）协商密钥并创建会话

每次启动一个Guest VM被称为一次会话（session），Guest Owner需要为这一个session生成GODH密钥，然后和平台发来的证书链（包含PDH）一起生成master secret。从master secret派生出KEK、KIK，以及一组随机生成的TEK、TIK和密钥。把这些密钥一起生成session parameters。Hypervisor在启动VM时，会将GODH和session parameters其作为LAUNCH_START的参数传递给PSP。

> 在生产环境中，请不要重复使用之前的GODH，以防平台拥有者对你发起重放攻击。

```sh
sevctl session -n 'sev' /tmp/sev.pdh 5
```

其中`'sev'`是我指定的密钥名字，`/tmp/sev.pdh`是从平台拿到的证书链 `5`是启动Guest VM时的policy值（Guest Owner应该控制这个值以避免由配置导致的安全问题）。

这将在当前目录下产生若个文件
- sev_godh.b64：GODH(Guest Owner Diffie-Hellman key)，它和PDH都是[ECDH](https://en.wikipedia.org/wiki/Elliptic-curve_Diffie%E2%80%93Hellman)密钥，在交换公钥之后双方可以生成一致的master secret。
- sev_session.b64：session parameters，包含了由KEK和KIK共同保护的TEK和TIK，以及一个和session有关的NONCE值
  ![](/images/2023-04-17-21-35-24.png)
- sev_tek.bin：TEK(Transport Encryption Key)，一个AES-128密钥。用于加密Guest Owner和Firmware之间传输的数据
- sev_tik.bin：TIK(Transport Integrity Key)，一个HMAC密钥。用于对Guest Owner和Firmware之间传输的数据实施完整性保护。

使用scp将sev_godh.b64和sev_session.b64发送到平台侧用于启动VM，其余的两个文件由Relying Party保留。

### （平台）启动Guest VM并进行度量

与libvirt不同，pve并未提供在启动时度量Guest VM状态的命令，我们需要对pve启动qemu时的参数进行一些修改。

同样，在pve host上，使用`qm showcmd`查看qemu启动命令

我们要做以下修改
1. 使用我们自己编译的OVMF.fd而不是pve提供的
   ```txt
     -drive 'if=pflash,unit=0,format=raw,readonly=on,file=/usr/share/pve-edk2-firmware//OVMF_CODE_4M.secboot.fd' \
   ```
   改成
   ```txt
     -drive 'if=pflash,unit=0,format=raw,readonly=on,file=./OVMF.fd' \
   ```
2. 增加sev相关的选项，尤其是sev-guest选项要增加参数`dh-cert-file=<file1>,session-file=<file2>`
    > qemu [man-page](https://www.qemu.org/docs/master/system/qemu-manpage.html):
    > 
    > The dh-cert-file and session-file provides the guest owner’s Public Diffie-Hillman key defined in SEV spec. The PDH and session parameters are used for establishing a cryptographic session with the guest owner to negotiate keys used for attestation. The file must be encoded in base64.

    例如在我的实验中中，使用以下选项 
    ```txt
      -object 'sev-guest,id=sev0,cbitpos=47,reduced-phys-bits=1,policy=0x5,dh-cert-file=/tmp/sev_godh.b64,session-file=/tmp/sev_session.b64' \
      -machine 'memory-encryption=sev0'
    ```

3. 在其中插入一个`-S`选项，这样可以[在启动后暂停VM](https://www.qemu.org/docs/master/system/managed-startup.html)，我们有机会进行度量。

改完之后的命令如下

```sh
/usr/bin/kvm \
  -id 114 \
  -name 'pve-sev,debug-threads=on' \
  -no-shutdown \
  -chardev 'socket,id=qmp,path=/var/run/qemu-server/114.qmp,server=on,wait=off' \
  -mon 'chardev=qmp,mode=control' \
  -chardev 'socket,id=qmp-event,path=/var/run/qmeventd.sock,reconnect=5' \
  -mon 'chardev=qmp-event,mode=control' \
  -pidfile /var/run/qemu-server/114.pid \
  -daemonize \
  -smbios 'type=1,uuid=1fe437a6-eac4-48c3-9640-298b4a370cf6' \
  -drive 'if=pflash,unit=0,format=raw,readonly=on,file=./OVMF.fd' \
  -drive 'if=pflash,unit=1,id=drive-efidisk0,format=qcow2,file=/mnt/sandisk2t-data/pve-storage//images/114/vm-114-disk-0.qcow2' \
  -smp '8,sockets=1,cores=8,maxcpus=8' \
  -nodefaults \
  -boot 'menu=on,strict=on,reboot-timeout=1000,splash=/usr/share/qemu-server/bootsplash.jpg' \
  -vnc 'unix:/var/run/qemu-server/114.vnc,password=on' \
  -cpu 'EPYC-Rome,enforce,+kvm_pv_eoi,+kvm_pv_unhalt,vendor=AuthenticAMD' \
  -m 4096 \
  -object 'iothread,id=iothread-virtioscsi0' \
  -readconfig /usr/share/qemu-server/pve-q35-4.0.cfg \
  -device 'vmgenid,guid=f277a770-a44d-4ee0-a169-6db7a64677f5' \
  -device 'qxl-vga,id=vga,max_outputs=4,bus=pcie.0,addr=0x1' \
  -chardev 'socket,path=/var/run/qemu-server/114.qga,server=on,wait=off,id=qga0' \
  -device 'virtio-serial,id=qga0,bus=pci.0,addr=0x8' \
  -device 'virtserialport,chardev=qga0,name=org.qemu.guest_agent.0' \
  -device 'virtio-serial,id=spice,bus=pci.0,addr=0x9' \
  -chardev 'spicevmc,id=vdagent,name=vdagent' \
  -device 'virtserialport,chardev=vdagent,name=com.redhat.spice.0' \
  -spice 'tls-port=61000,addr=127.0.0.1,tls-ciphers=HIGH,seamless-migration=on' \
  -device 'virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0x3,free-page-reporting=on' \
  -iscsi 'initiator-name=iqn.1993-08.org.debian:01:fc5232458f32' \
  -drive 'file=/mnt/seagate4t/pve-backup/template/iso/archlinux-2023.03.01-x86_64.iso,if=none,id=drive-ide2,media=cdrom,aio=io_uring' \
  -device 'ide-cd,bus=ide.1,unit=0,drive=drive-ide2,id=ide2,bootindex=101' \
  -device 'virtio-scsi-pci,id=virtioscsi0,bus=pci.3,addr=0x1,iothread=iothread-virtioscsi0' \
  -drive 'file=/mnt/sandisk2t-data/pve-storage//images/114/vm-114-disk-1.qcow2,if=none,id=drive-scsi0,discard=on,format=qcow2,cache=none,aio=io_uring,detect-zeroes=unmap' \
  -device 'scsi-hd,bus=virtioscsi0.0,channel=0,scsi-id=0,lun=0,drive=drive-scsi0,id=scsi0,rotation_rate=1,bootindex=100' \
  -netdev 'type=tap,id=net0,ifname=tap114i0,script=/var/lib/qemu-server/pve-bridge,downscript=/var/lib/qemu-server/pve-bridgedown,vhost=on' \
  -device 'virtio-net-pci,mac=96:27:59:37:8F:1C,netdev=net0,bus=pci.0,addr=0x12,id=net0,rx_queue_size=1024,tx_queue_size=1024' \
  -netdev 'type=tap,id=net1,ifname=tap114i1,script=/var/lib/qemu-server/pve-bridge,downscript=/var/lib/qemu-server/pve-bridgedown,vhost=on' \
  -device 'virtio-net-pci,mac=16:C8:90:53:5B:A9,netdev=net1,bus=pci.0,addr=0x13,id=net1,rx_queue_size=1024,tx_queue_size=1024' \
  -machine 'type=q35+pve0' \
  -object 'sev-guest,id=sev0,cbitpos=47,reduced-phys-bits=1,policy=0x5,dh-cert-file=/tmp/sev_godh.b64,session-file=/tmp/sev_session.b64' \
  -S \
  -machine 'memory-encryption=sev0'
```

用改后的参数启动qemu，此时PVE Web面板会显示该VM处于`running (prelaunch)`状态。


上面的命令同时开启了unix domain socket，路径为`/var/run/qemu-server/114.qmp`。这是一个[QMP接口（QEMU Machine Protocol）](https://wiki.qemu.org/Documentation/QMP)，通过它我们可以向qemu虚拟机发送一些控制指令。

可以使用nc或者socat连接到它：
```sh
socat - UNIX-CONNECT:/var/run/qemu-server/114.qmp
```
连接上后立刻收到了如下信息
```json
{"QMP": {"version": {"qemu": {"micro": 0, "minor": 2, "major": 7}, "package": "pve-qemu-kvm_7.2.0-8"}, "capabilities": []}}
```
这时我们处于`capabilities negotiation`模式，我们通过发送以下内容来进入`command mode`
```json
{ "execute": "qmp_capabilities" }
```
得到
```json
{"return": {}}
```
紧接着，可以通过一下请求查询qmp所支持的所有命令
```json
{ "execute": "query-commands" }
```
输出过长此处省略

QMP支持的命令的描述及examples，可以在[这里](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html)找到。这里我只介绍一些我们用到的：

查询平台的sev信息
```json
{ "execute": "query-sev" }
```
输出：
```json
{"return": {"enabled": true, "api-minor": 24, "handle": 1, "state": "launch-secret", "api-major": 0, "build-id": 15, "policy": 5}}
```

查询度量值
```json
{ "execute": "query-sev-launch-measure" }
```
输出:
```json
{"return": {"data": "ychmE35DRiv54GcbbM+igqxwfoshDLDVH0C7G8Ig0psQrgLNRNeZPPMzelvBwnZD"}}
```

其中data字段的base64值就是度量结果，这是一个48bytes的数据。根据[文档](https://www.amd.com/system/files/TechDocs/55766_SEV-KM_API_Specification.pdf)中的`Table 52: LAUNCH_MEASURE Measurement Buffer`章节，它的结构是
```txt
MEASURE(32bytes) || MNONCE(16bytes)
```

1. `MEASURE`
  在`6.5 LAUNCH_MEASURE`章节，描述了`MEASURE`其实是一个HMAC值

  ```txt
  HMAC(0x04 || API_MAJOR || API_MINOR || BUILD || GCTX.POLICY || GCTX.LD || MNONCE; GCTX.TIK)
  ```

  具体的细节也可以参考[QEMU文档](https://www.qemu.org/docs/master/system/i386/amd-memory-encryption.html#calculating-expected-guest-launch-measurement)中的描述。
2. `MNONCE`
  MNONCE是由firmware生成的nonce值，目的是防止敌手发起重放攻击。

平台需要要把这两个数据一并发给Relaying Party。

> 所谓度量是一个计算内存hash的过程，PSP内部维护了guest vm的一个状态机。当Hypervisor运行`LAUNCH_START`命令之后，vm处于`GSTATE.LUPDATE`状态，此时Hypervisor可以通过对多个内存区域执行`LAUNCH_UPDATE_DATA`，然后PSP会使用该区域的值来更新当前VM的hash值，并将对应区域的数据使用这个VM对应的VEK密钥进行加密。如果是SEV-ES，Hypervisor还可以通过`LAUNCH_UPDATE_VMSA`命令来对VM的VMCB save area做上述hash值更新和内存加密操作。最后Hypervisor通过`LAUNCH_MEASURE`命令生成一个度量结果，并将状态转换为`GSTATE.LSECRET`，此时无法再使用`LAUNCH_UPDATE_DATA`和`LAUNCH_UPDATE_VMSA`命令。
<!-- 能否对同一个内存执行多次LAUNCH_UPDATE_DATA从而反复加密？构造类似于彩虹表的东西？ -->

### （Relaying Party）验证度量值

现在转到Relaying Party侧。Guest VM已经度量好，正等着我们验证呢。

1. 构建VMSA binary
    如果你是SEV-ES，那么在此之前，还有一项内容，就是构建VMSA binary。这也是SEV-ES相比于SEV多出来的一部分，它额外度量了每个Guest vCPU的VMSA区域，并在运行时提供加密保护。

    因此我们的Guest Owner在验证度量值时，也需要计算出VMSA区域的初始值（也就是VMSA binary），并把它纳入度量过程中。

    首先需要知道Guest vCPU的一些信息。可以使用qmp中的`"query-cpu-model-expansion"`命令，其中参数`"name"`需要根据你的qemu命令行中指定的`-cpu`选项进行调整。

    比如我的命令是：
    ```json
    { "execute": "query-cpu-model-expansion", "arguments": { "type": "static", "model": { "name": "EPYC-Rome" } } }
    ```
    输出：
    ```json
    {"return": {"model": {"name": "base", "props": {"vmx-entry-load-rtit-ctl": false, "svme-addr-chk": false, "cmov": true, "ia64": false, "ssb-no": false, "aes": true, "vmx-apicv-xapic": false, "mmx": true, "rdpid": true, "arat": true, "vmx-page-walk-4": false, "vmx-page-walk-5": false, "gfni": false, "ibrs-all": false, "vmx-desc-exit": false, "pause-filter": false, "bus-lock-detect": false, "xsavec": true, "intel-pt": false, "vmx-tsc-scaling": false, "vmx-cr8-store-exit": false, "vmx-rdseed-exit": false, "vmx-eptp-switching": false, "kvm-asyncpf": true, "perfctr-core": true, "mpx": false, "pbe": false, "avx512cd": false, "decodeassists": false, "vmx-exit-load-efer": false, "vmx-exit-clear-bndcfgs": false, "sse4.1": true, "family": 23, "intel-pt-lip": false, "vmx-vmwrite-vmexit-fields": false, "kvm-asyncpf-int": false, "vmx-vnmi": false, "vmx-true-ctls": false, "vmx-ept-execonly": false, "vmx-exit-save-efer": false, "vmx-invept-all-context": false, "wbnoinvd": true, "avx512f": false, "msr": true, "mce": true, "mca": true, "xcrypt": false, "sgx": false, "vmx-exit-load-pat": false, "vmx-intr-exit": false, "min-level": 13, "vmx-flexpriority": false, "xgetbv1": true, "cid": false, "sgx-exinfo": false, "ds": false, "fxsr": true, "avx512-fp16": false, "avx512-bf16": false, "vmx-cr8-load-exit": false, "xsaveopt": true, "arch-lbr": false, "vmx-apicv-vid": false, "vmx-exit-save-pat": false, "xtpr": false, "tsx-ctrl": false, "vmx-ple": false, "avx512vl": false, "avx512-vpopcntdq": false, "phe": false, "extapic": false, "3dnowprefetch": true, "vmx-vmfunc": false, "vmx-activity-shutdown": false, "sgx1": false, "sgx2": false, "avx512vbmi2": false, "cr8legacy": true, "vmx-encls-exit": false, "stibp": false, "vmx-msr-bitmap": false, "xcrypt-en": false, "vmx-mwait-exit": false, "vmx-pml": false, "vmx-nmi-exit": false, "amx-tile": false, "vmx-invept-single-context-noglobals": false, "pn": false, "rsba": false, "dca": false, "vendor": "AuthenticAMD", "vmx-unrestricted-guest": false, "vmx-cr3-store-noexit": false, "pku": false, "pks": false, "smx": false, "cmp-legacy": false, "avx512-4fmaps": false, "vmcb-clean": false, "hle": false, "avx-vnni": false, "3dnowext": false, "amd-no-ssb": false, "npt": false, "sgxlc": false, "rdctl-no": false, "vmx-invvpid": false, "clwb": true, "lbrv": false, "adx": true, "ss": false, "pni": true, "tsx-ldtrk": false, "svm-lock": false, "smep": true, "smap": true, "pfthreshold": false, "vmx-invpcid-exit": false, "amx-int8": false, "x2apic": true, "avx512vbmi": false, "avx512vnni": false, "vmx-apicv-x2apic": false, "kvm-pv-sched-yield": false, "vmx-invlpg-exit": false, "vmx-invvpid-all-context": false, "vmx-activity-hlt": false, "flushbyasid": false, "f16c": true, "vmx-exit-ack-intr": false, "ace2-en": false, "pae": true, "pat": true, "sse": true, "phe-en": false, "vmx-tsc-offset": false, "kvm-nopiodelay": true, "tm": false, "kvmclock-stable-bit": true, "vmx-rdtsc-exit": false, "hypervisor": true, "vmx-rdtscp-exit": false, "mds-no": false, "pcommit": false, "vmx-vpid": false, "syscall": true, "avx512dq": false, "svm": false, "invtsc": false, "vmx-monitor-exit": false, "sse2": true, "ssbd": false, "vmx-wbinvd-exit": false, "est": false, "kvm-poll-control": false, "avx512ifma": false, "tm2": false, "kvm-pv-eoi": true, "kvm-pv-ipi": false, "cx8": true, "vmx-invvpid-single-addr": false, "waitpkg": false, "cldemote": false, "sgx-tokenkey": false, "vmx-ept": false, "xfd": false, "kvm-mmu": false, "sse4.2": true, "pge": true, "avx512bitalg": false, "pdcm": false, "vmx-entry-load-bndcfgs": false, "vmx-exit-clear-rtit-ctl": false, "model": 49, "movbe": true, "nrip-save": false, "ssse3": true, "sse4a": true, "kvm-msi-ext-dest-id": false, "vmx-pause-exit": false, "invpcid": false, "sgx-debug": false, "pdpe1gb": true, "sgx-mode64": false, "tsc-deadline": false, "skip-l1dfl-vmentry": false, "vmx-exit-load-perf-global-ctrl": false, "fma": true, "cx16": true, "de": true, "stepping": 0, "xsave": true, "clflush": true, "skinit": false, "tsc": true, "tce": false, "fpu": true, "ds-cpl": false, "ibs": false, "fma4": false, "vmx-exit-nosave-debugctl": false, "sgx-kss": false, "la57": false, "vmx-invept": false, "osvw": true, "apic": true, "pmm": false, "vmx-entry-noload-debugctl": false, "vmx-eptad": false, "spec-ctrl": false, "vmx-posted-intr": false, "vmx-apicv-register": false, "tsc-adjust": false, "kvm-steal-time": true, "avx512-vp2intersect": false, "kvmclock": true, "vmx-zero-len-inject": false, "pschange-mc-no": false, "v-vmsave-vmload": false, "vmx-rdrand-exit": false, "sgx-provisionkey": false, "lwp": false, "amd-ssbd": false, "xop": false, "ibpb": true, "ibrs": false, "avx": true, "core-capability": false, "vmx-invept-single-context": false, "movdiri": false, "acpi": false, "avx512bw": false, "ace2": false, "fsgsbase": true, "vmx-ept-2mb": false, "vmx-ept-1gb": false, "ht": false, "vmx-io-exit": false, "nx": true, "pclmulqdq": true, "mmxext": true, "popcnt": true, "vaes": false, "serialize": false, "movdir64b": false, "xsaves": true, "vmx-shadow-vmcs": false, "lm": true, "vmx-exit-save-preemption-timer": false, "vmx-entry-load-pat": false, "fsrm": false, "vmx-entry-load-perf-global-ctrl": false, "vmx-io-bitmap": false, "umip": true, "vmx-store-lma": false, "vmx-movdr-exit": false, "pse": true, "avx2": true, "avic": false, "sep": true, "virt-ssbd": false, "vmx-cr3-load-noexit": false, "nodeid-msr": false, "md-clear": false, "misalignsse": true, "split-lock-detect": false, "min-xlevel": 2147483679, "bmi1": true, "bmi2": true, "kvm-pv-unhalt": true, "tsc-scale": false, "topoext": true, "amd-stibp": true, "vmx-preemption-timer": false, "clflushopt": true, "vmx-entry-load-pkrs": false, "vmx-vnmi-pending": false, "monitor": false, "vmx-vintr-pending": false, "avx512er": false, "full-width-write": false, "pmm-en": false, "pcid": false, "taa-no": false, "arch-capabilities": false, "vgif": false, "vmx-secondary-ctls": false, "vmx-xsaves": false, "clzero": true, "3dnow": false, "erms": false, "vmx-entry-ia32e-mode": false, "lahf-lm": true, "vpclmulqdq": false, "vmx-ins-outs": false, "fxsr-opt": true, "xstore": false, "rtm": false, "kvm-hint-dedicated": false, "amx-bf16": false, "lmce": false, "perfctr-nb": false, "rdrand": true, "rdseed": true, "avx512-4vnniw": false, "vme": true, "vmx": false, "dtes64": false, "mtrr": true, "rdtscp": true, "xsaveerptr": true, "pse36": true, "kvm-pv-tlb-flush": false, "vmx-activity-wait-sipi": false, "tbm": false, "wdt": false, "vmx-rdpmc-exit": false, "vmx-mtf": false, "vmx-entry-load-efer": false, "model-id": "AMD EPYC-Rome Processor", "sha-ni": true, "vmx-exit-load-pkrs": false, "abm": true, "vmx-ept-advanced-exitinfo": false, "avx512pf": false, "vmx-hlt-exit": false, "xstore-en": false}}}}
    ```
    主要用到的是上面的`model`、`family`、`stepping`信息，这几个值将决定VMSA中的`rdx`寄存器的值。

    构建vCPU0的VMSA binary：    
    ```sh
    sevctl vmsa build NEW-VMSA0.bin --userspace qemu --family 23 --stepping 0 --model 49 --firmware ./OVMF.fd --cpu 0
    ```
    如果是多个核心，还需要生成其余核心的VMSA binary。不过由于其余的VMSA binary都是一样的，只需要为vCPU1生成一次就行：
    ```sh
    sevctl vmsa build NEW-VMSA1.bin --userspace qemu --family 23 --stepping 0 --model 49 --firmware ./OVMF.fd --cpu 1
    ```
2. 计算度量值
    ```sh
    sevctl measurement build \
        --api-major 0 --api-minor 24 --build-id 15 \
        --policy 0x05 \
        --tik sev_tik.bin \
        --launch-measure-blob ychmE35DRiv54GcbbM+igqxwfoshDLDVH0C7G8Ig0psQrgLNRNeZPPMzelvBwnZD \
        --firmware ./OVMF.fd \
        --num-cpus 8 \
        --vmsa-cpu0 ./NEW-VMSA0.bin \
        --vmsa-cpu1 ./NEW-VMSA1.bin
    ```

    其中：
    - `--api-major`、`--api-minor`、`--build-id`、`--policy`可以通过qmp里的`{ "execute": "query-sev" }`命令查询到
    - `--policy` 和启动Guest VM时指定的policy一致
    - `--firmware`是我们使用的OVMF.fd的路径
      > 除了firmware，还支持加入其它的度量值如`--kernel`, `--initrd`, `--cmdline`。不过由于我们给qemu只指定了firmware的路径，所以qemu只度量了firmware。所以我们在验证的时候也只度量firmware。
    - 传入`--launch-measure-blob`的目的是获取末尾的MNONCE值。
    - 如果是SEV-SNP，则需提供
      - `--num-cpus`：Guest VM的cpu数量
      - `--vmsa-cpu0`、`--vmsa-cpu1`：每个CPU的vmsa区域初始值。如果是多于一个vCPU，则需要指定`--vmsa-cpu1`

    输出如下
    ```txt
    ychmE35DRiv54GcbbM+igqxwfoshDLDVH0C7G8Ig0psQrgLNRNeZPPMzelvBwnZD
    ```

    可见和我们从平台处拿到的度量结果是一致的。

至此我们证明了这么一件事：有一个经过AMD验证的平台，这个平台向我们证明了它上面运行了我们预期的Guest VM。但是我们还差一步，那就是向这个Guest VM注入我们的机密数据，这样我们可以进一步与它上面的应用建立可信信道。

### （Relaying Party）生成secret

所谓的secret是若干个`<GUID, Value>`组成的键值对，借助`sevctl`，可以将其打包成一个binary，然后经过TEK加密以及TIK进行的HMAC保护。随后该binary被发送给AMD PSP。在执行SEV的`LAUNCH_SECRET`命令时，由PSP使用TEK解密payload，然后用VEK加密并放入到Guest VM里指定的内存区域。

<!-- LAUNCH_SECRET并未限制目标的GUEST_PADDR，是否有可能写入到之前已经被加密过的内存区域从而任意覆盖值？ -->
<!-- 执行LAUNCH_SECRET之后GSTAT并未转变，这是否意味着在在LAUNCH_FINISH之前（即VM处于RUNNING状态之前）可以多次调用LAUNCH_SECRET -->

> 在实际应用中，这个secret通常存储一个密钥。比如grub里面有一个cryptodisk模块，会使用一个secret来解密经过luks加密的磁盘，它的guid是`736869e5-84f0-4973-92ec-06879ce3da0b`。

在这个实验中，我们定义了一个GUID为`43ced044-42ec-487a-88b7-261bda359f24`的secret，值为`"TOP_SECRET_MESSAGE"`这个字符串。

```sh
echo "TOP_SECRET_MESSAGE" > ./secret.txt

sevctl secret build \
    --tik sev_tik.bin \
    --tek sev_tek.bin \
    --launch-measure-blob ychmE35DRiv54GcbbM+igqxwfoshDLDVH0C7G8Ig0psQrgLNRNeZPPMzelvBwnZD \
    --secret 43ced044-42ec-487a-88b7-261bda359f24:./secret.txt \
    ./secret_header.bin \
    ./secret_payload.bin
```
输出
```txt
Wrote header to: ./secret_header.bin
Wrote payload to: ./secret_payload.bin
```

我们将输出的两个文件用scp发到平台

### （平台）将secret植入Guest VM

首先用base64命令将secret_header.bin和secret_payload.bin转为base64编码

得到：
- `base64 -w 0 < secret_header.bin`：`AAAAAKzd9a3vLYPW4fcwzlsAq+YY6Vhlqcj65QvIzqy3Mc+XPiyzEsCsmKKIpk8SfnAF7w==`
- `base64 -w 0 < secret_payload.bin`：`s1Ua7oK6RH54g97oWgV1XWqQw4vpZLpfAL2oCVG9uLhjB+dzHxeKnQbxaiQ8ibSUedTfZx28QIz7tKaRh12mIg==`

在QMP中，使用`sev-inject-launch-secret`命令，并用上面两个参数作为值
```json
{ "execute": "sev-inject-launch-secret", "arguments": { "packet-header": "AAAAAKzd9a3vLYPW4fcwzlsAq+YY6Vhlqcj65QvIzqy3Mc+XPiyzEsCsmKKIpk8SfnAF7w==", "secret": "s1Ua7oK6RH54g97oWgV1XWqQw4vpZLpfAL2oCVG9uLhjB+dzHxeKnQbxaiQ8ibSUedTfZx28QIz7tKaRh12mIg==" } }
```
返回
```json
{"return": {}}
```

使用`cont`命令继续运行VM

```json
{ "execute": "cont" }
```

### （Guest VM）OS启动并获取植入的secret

前面说到，所有的secret被写入到内存的特定区域。这个区域的地址是由UEFI（在虚拟机中就是OVMF firmware）暴露给qemu的，随后UEFI会在EFI configuration table中创建一个GUID为`adf956ad-e98c-484c-ae11-b51c7d336447`的条目，并对该内存区域做一个`EFI_RESERVED_TYPE`标记告诉bootloader和kernel不要覆盖了这块内存。

Linux内核增加了对识别SEV植入的secret值的支持，这是通过一个叫`efi_secret`的内核模块实现的，它会根据GUID识别EFI configuration table里的条目，并从该条目指示的内存地址中解析我们的secret，并暴露在一个虚拟的文件系统中。

感兴趣的读者可以阅读[这篇短文章](https://docs.kernel.org/5.19/security/secrets/coco.html)

1. 确保Guest VM检测到了SEV支持
    ```sh
    dmesg | grep -i sev
    ```
    应该显示`Memory Encryption Features active: AMD SEV`

2. 载入`efi_secret`内核模块
    ```sh
    modprobe efi_secret
    ```

3. 挂载`securityfs`
    ```sh
    mount -t securityfs securityfs /sys/kernel/security
    ```

4. 检查secret值

    所有的secret值在/sys/kernel/security/secrets/coco目录下，以secret的GUID作为文件名，读取该文件就能得到secret的内容
    ```sh
    ls -la /sys/kernel/security/secrets/coco/
    ```

下图是我们的实验结果，其中运行的Guest VM是一个archiso镜像
![](/images/2023-04-17-13-35-51.png)

可以看到我们成功读出了我们注入的secret的值`TOP_SECRET_MESSAGE`。

## 总结

这一趟配置过程花了不少时间，不过也是圆了我最初组这一套设备时的一个想法吧，总的来说还是比较有趣的。相比于繁杂的SGX，SEV和SEV-ES就显得清晰了很多（当然一些方面比如CEK能够标识一个CPU，这样隐私性就弱了些了，然后也没有证书撤销列表这种东西），在这个过程中可以看出AMD在设计这个方案中的一些安全考虑，比如`pre-attestation`过程中的session nonce和measure nonce值的使用。

但是也可以看出这个方案中的一些缺陷，比如secret的植入过程会要求Guest Owner在Guest VM启动前就参与进来。如果可以再进一步，比如PSP在开启Guest VM后，就自动为该VM生成一对非对称密钥。用平台上的PEK为这个Guest VM签一个证书，里面包含公钥和VM的度量值等信息，然后把私钥以secret的信息放到VM里面，就可以节省掉很多环节。在新版本的PSP中，增加了一个名为`ATTESTATION`的命令，它允许在VM的处于运行状态时，生成一个attestation report，包含了度量值信息并由PEK签名。但是遗憾的是它只是提供了一种方式获取之前度量的结果，没有解决在LAUNCH_START和LAUNCH_MEASURE阶段需要Guest Owner参与的问题。

另外是关于pve平台的问题，在这个实验中也算是理解了pve没有内置sev支持的原因：最大的问题在于远程证明。如果不做远程证明，那为Guest VM开SEV只是代表了内存加密，但是并不能保证固件、Kernel等的安全性，用户无法相信上面的软件是安全的。而如果要做远程证明，就变得麻烦了起来，需要平台和用户配合起来完成，这对于PVE来说显然是太复杂了。还是特定场景比如kata容器这样的更适合。

<!-- 

TODO：sevtool可以查询OCA的出处？？ Or it can be given to you by the cloud service provider (in this latter case you’ll want to verify the provenance using sevtool –validate_cert_chain, which contacts the AMD site to verify all the details). Once you have a trusted pdh.cert, you can use this to generate your own guest owner DH cert (godh.cert) which should be used only one time to give a semblance of ECDHE. godh.cert is used with pdh.cert to derive an encryption key for the launch bundle. You can generate this with

TODO：解决启动时需要Guest Owner参与的这个问题的方法，是用一些硬件安全模块HSM？？The next annoyance is that launching a confidential VM is high touch requiring collaboration from both the guest owner and the host owner (due to the anti-replay nonce). For a single launch, this is a minor annoyance but for an autoscaling (launch VMs as needed) platform it becomes a major headache. The solution seems to be to have some Hardware Security Module (HSM), like the cloud uses today to store encryption keys securely, and have it understand how to measure and launch encrypted VMs on behalf of the guest owner.

TODO：机密虚拟机和普通虚拟机面临着一样的威胁，Confidential VMs do have an answer to the Cloud trust problem since the enterprise can now deploy VMs without fear of tampering by the cloud provider, but those VMs are as insecure in the cloud as they were in the Enterprise Data Centre.


- [x] 为什么没有注入dh-cert-file和session-file也能拿到measure
  - 在内核的kvm模块中，[代码](https://github.com/torvalds/linux/blob/6a8f57ae2eb07ab39a6f0ccad60c760743051026/arch/x86/kvm/svm/sev.c#L332-L351)对于这一块的处理是：如果qemu没有传GODH，那么调用LAUNCH_START时的DH_CERT_PADDR和SESSION_PADDR就传0值，不知道此时PSP会如何处理，如何生成master secret、KEK、TEK，以及TEK和TIK又从哪来，如果是固定值，是否能够泄漏出PDH的私钥信息。
 -->


## 参考：
- [AMD Secure Encrypted Virtualization API](https://www.amd.com/system/files/TechDocs/55766_SEV-KM_API_Specification.pdf)
- [Confidential Computing secrets - Linux Kernel Doc](https://docs.kernel.org/5.19/security/secrets/coco.html) 
- EDKII中与secret相关的几个pr：
  - https://github.com/tianocore/edk2/pull/1175
  - https://github.com/tianocore/edk2/pull/1235
- James Bottomley（上述PR的主要作者）的文章
  - [Deploying Encrypted Images for Confidential Computing](https://blog.hansenpartnership.com/deploying-encrypted-images-for-confidential-computing/)
