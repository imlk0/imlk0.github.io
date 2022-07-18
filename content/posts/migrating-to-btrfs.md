---
title: "从ext4迁移到btrfs"
date: 2022-01-12T11:21:41+08:00
categories:
  - Linux
tags:
  - btrfs
  - grub
---

今天尝试了将根文件系统迁移到btrfs，主要是看中了它的Copy-on-Write以及透明压缩和快照等特性。鉴于没有找到现成的完整教程，加上子卷的划分其实看个人偏好，故做此文，顺便把在这期间遇到的问题记录一下。

整个迁移过程是在LiveCD中操作的。

## 创建btrfs

将原先的rootfs备份后，格式化为btrfs，工具任意，这里我用的gnome自带的磁盘管理程序，GPartd应该也可以。

![](/images/blog/btrfs_1.png)

- 挂载btrfs分区到临时目录`/mnt/btrfs`

  ```bash
  sudo mount -t btrfs -o compress=zstd /dev/sdb4 /mnt/btrfs
  ```

  注意默认不会开启压缩功能，因此这里最好就加上`-o compress=zstd`，因为我们一会还得将之前备份的文件拷贝回来。

  如果想要了解压缩算法的选择，可以参考[https://btrfs.wiki.kernel.org/index.php/Compression](https://btrfs.wiki.kernel.org/index.php/Compression)

## 创建子卷

### btrfs子卷布局

推荐阅读[https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Layout](https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Layout)

如果关心快照，还可以阅读：[https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Snapshots](https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Snapshots)

btrfs的子卷布局很随意，一般有三种范式：Flat、Nested、Mixed，上面Flat和Nested区别在于：后者的subvolume底下还有subvolume（注意快照时不会递归对里面的subvolume做快照），而Flat则倾向于将所有的subvolume平铺。

在考虑便捷性和快照后，我参考Flat布局制定了下面这样的布局

```
/               <root卷，不挂载>
├── snapshots   <目录，用于之后存放快照卷>
└── subvolumes  <目录，新增的子卷也都放在这下面>
    ├── home    <子卷，挂载为/home>
    └── root    <子卷，挂载为/>
```

### 创建子卷

- 创建两个目录存放常规的subvolumes和快照用的snapshots

  ```bash
  sudo mkdir /mnt/btrfs/subvolumes
  sudo mkdir /mnt/btrfs/snapshots
  ```

- 创建两个subvolume

  ```bash
  sudo btrfs subvolume create /mnt/btrfs/subvolumes/root
  sudo btrfs subvolume create /mnt/btrfs/subvolumes/home
  ```

可以使用`sudo btrfs subvolume list -p /mnt/btrfs`查看这两个subvolume的id

现在，可以直接访问`/mnt/btrfs/subvolumes/root`和`/mnt/btrfs/subvolumes/home`，并将之前备份的文件拷贝回来。

## 更新grub

这一步需要chroot到原来的rootfs里面，我们创建一个临时目录`/mnt/btrfs-root`来准备rootfs。

挂载两个subvolume：

```bash
sudo mount -t btrfs -o noatime,compress=zstd,subvol=/subvolumes/root /dev/sdb4 /mnt/btrfs-root
sudo mount -t btrfs -o noatime,compress=zstd,subvol=/subvolumes/home /dev/sdb4 /mnt/btrfs-root/home
```

mount bind必要的文件系统，然后chroot。（如果你的`/boot`目录在别的分区的，那么还需要额外挂载`/boot`）

```bash
cd /mnt/btrfs-root
sudo mount -o bind /dev  dev
sudo mount -o bind /sys sys
sudo mount -o bind /proc proc
sudo chroot .
```

更新grub配置

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

## 更新/etc/fstab

注意指定参数中的`compress`和`subvol`选项

```bash
UUID=7f208f70-fee3-4bbe-8f3f-c1e95dd25afe  /  btrfs  defaults,noatime,compress=zstd,subvol=/subvolumes/root 0 1
UUID=7f208f70-fee3-4bbe-8f3f-c1e95dd25afe  /home  btrfs  defaults,noatime,compress=zstd,subvol=/subvolumes/home 0 0
```

## 关于压缩

如果你像我一样在恢复文件之前忘了加压缩选项，可以使用下面的命令分别压缩每个子卷里的现存文件

```bash
sudo btrfs filesystem defragment -r -v -czstd /mnt/btrfs/subvolumes/root
sudo btrfs filesystem defragment -r -v -czstd /mnt/btrfs/subvolumes/home
```

可以使用[compsize](https://github.com/kilobyte/compsize)这个工具计算压缩率。我这里顺便测试了一下压缩效果，与[gnome-disks](https://wiki.gnome.org/Apps/Disks)的结果进行比较。其中gnome-disks显示的是文件系统已用空间，compsize的统计方式似乎不太一样：

| 压缩范围\统计方法                          | gnome-disks | compsize     |
| ------------------------------------------ | ----------- | ------------ |
| 压缩前                                     | 140G        | 128G（100%） |
| 压缩/subvolumes/root子卷                   | 100G        | 89G（69%）   |
| 压缩/subvolumes/root和/subvolumes/home子卷 | 66G         | 56G（44%）   |

![同时压缩`/`和`/home`子卷的结果](/images/blog/btrfs_2.png)

## 关于坑

整体来看其实是没有什么坑的（其实遇到的坑也是自己挖的

就写一下迁移过程中遇到的一些问题8：

1. 备份：因为是在LiveCD里操作的，本来备份文件的时候打算使用TimeShift的rsync模式，但是TimeShift无法在LiveCD里面使用，不知道开发者是怎么考虑的。最后换用了LuckyBackup（虽然都是rsync但是就是懒得自己写命令hhh）
2. btrfs-convert：这工具可以原地把ext4转换为btrfs，但是似乎受到空闲块数量的限制，我测试了几次发现在不同的地方报failed，即使整个ext4文件系统只使用大概50%的空间。最后索性直接格式化成btrfs再拷贝回去了。
3. grub unknown filesystem：改完之后grub直接进到resuce救援模式，发现无法识别btrfs分区。这个其实是我之前乱改了EFI分区里的内容导致的，其中的grub efi文件是很旧的版本，不认识btrfs，也就没法加载`/boot/grub/x86_64-efi/`里的grub模块文件，导致救援模式里基本上啥也不能干。最后是把EFI分区也挂载上，在chroot里使用`grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB`之类的命令重新生成了一下EFI分区中的`grubx64.efi`
