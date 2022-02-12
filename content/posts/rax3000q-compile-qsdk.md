---
title: "从QSDK源码编译RAX3000Q所需的软件包"
date: 2022-02-10T21:37:50+08:00
categories:
  - Router
tags:
  - 路由器
  - OpenWrt
draft: false
---















前一篇文章中讲到了如何开启RAX3000Q的ssh，并且发现其固件正是QSDK，但是并没有妥善解决软件包的问题，这一次我们尝试基于QSDK源码编译我们想要的软件包的ipk文件。

实践过程也是参考了很多网上的关于QSDK的文章。

我是在docker容器中构建的，环境是Ubuntu 20.04 （dockerhub上的`ubuntu:latest`），对于其他发行版如ArchLinux，在编译时可能需要解决宿主机上openssl头文件版本的问题，且本文中提到的patch可能不再适用。

# 获取源码

QSDK的源码管理类似于Android和ChromeOS，也基于[`repo`工具](https://gerrit.googlesource.com/git-repo/+/HEAD/README.md)，在开始之前需要先安装好`repo`。

QSDK的manifest文件存放在[这个仓库](https://source.codeaurora.org/quic/cc-qrdk/releases/manifest/qstak/)中，只有一个名为`release`的branch。在之前的分析中知道该路由器Openwrt版本为15.05和kernel版本为4.4，结合[QSDK的wiki](https://wiki.codeaurora.org/xwiki/bin/viewrev/QSDK/WebHome)，我选择了主版本号为11的QSDK的最新的manifest文件：`caf_AU_LINUX_QSDK_NHSS.QSDK.11.5.0.6_TARGET_ALL.11.5.0.6.055.xml`。

使用如下语句获取源码并初始化

```sh
repo init -u git://source.codeaurora.org/quic/cc-qrdk/releases/manifest/qstak -b release -m caf_AU_LINUX_QSDK_NHSS.QSDK.11.5.0.6_TARGET_ALL.11.5.0.6.055.xml
repo sync
```

> 请勿选择`caf_AU_LINUX_QSDK_NHSS.QSDK.12.0.R9_TARGET_ALL.12.0.09.841.011.xml`，测试发现其中的linux版本为5.4，且musl-libc版本与当前固件中的不符。

因为编译环境的问题，编译过程中（尤其是构建toolchain时）会导致很多error产生，在开始之前需要进行一些修改，这些修改多数是增加一些.patch文件，或者是对Makefile的一些改动。

其中大部分改动参考了[这篇文章](https://www.litreily.top/2021/02/07/qsdk-compile)

- qsdk/

  ```diff
  diff --git a/toolchain/gcc/patches/5.2.0/999-fix-too-many-template-parameters.patch b/toolchain/gcc/patches/5.2.0/999-fix-too-many-template-parameters.patch
  new file mode 100644
  index 000000000000..cab030714d2b
  --- /dev/null
  +++ b/toolchain/gcc/patches/5.2.0/999-fix-too-many-template-parameters.patch
  @@ -0,0 +1,94 @@
  +From 94801184df727b94bf7b8d64b1f98a22f51325d7 Mon Sep 17 00:00:00 2001
  +From: Elliot Saba <staticfloat@gmail.com>
  +Date: Mon, 22 Apr 2019 19:58:09 -0400
  +Subject: [PATCH] Remove double `tempate <>` declarations in `wide-int.h`
  +
  +This fixes compilation of GCC 5.2.0 with very recent compilers such as
  +GCC 8.3.0, which would otherwise fail with errors such as `error: too
  +many template-parameter-lists`
  +---
  + gcc/wide-int.h | 10 ----------
  + 1 file changed, 10 deletions(-)
  +
  +diff --git a/gcc/wide-int.h b/gcc/wide-int.h
  +index 46f45453c015..9a71c4fea61b 100644
  +--- a/gcc/wide-int.h
  ++++ b/gcc/wide-int.h
  +@@ -365,21 +365,18 @@ namespace wi
  +      inputs.  Note that CONST_PRECISION and VAR_PRECISION cannot be
  +      mixed, in order to give stronger type checking.  When both inputs
  +      are CONST_PRECISION, they must have the same precision.  */
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, FLEXIBLE_PRECISION, FLEXIBLE_PRECISION>
  +   {
  +     typedef widest_int result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, FLEXIBLE_PRECISION, VAR_PRECISION>
  +   {
  +     typedef wide_int result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, FLEXIBLE_PRECISION, CONST_PRECISION>
  +   {
  +@@ -389,14 +386,12 @@ namespace wi
  + 			       <int_traits <T2>::precision> > result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, VAR_PRECISION, FLEXIBLE_PRECISION>
  +   {
  +     typedef wide_int result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, CONST_PRECISION, FLEXIBLE_PRECISION>
  +   {
  +@@ -406,7 +401,6 @@ namespace wi
  + 			       <int_traits <T1>::precision> > result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, CONST_PRECISION, CONST_PRECISION>
  +   {
  +@@ -417,7 +411,6 @@ namespace wi
  + 			       <int_traits <T1>::precision> > result_type;
  +   };
  + 
  +-  template <>
  +   template <typename T1, typename T2>
  +   struct binary_traits <T1, T2, VAR_PRECISION, VAR_PRECISION>
  +   {
  +@@ -881,7 +874,6 @@ generic_wide_int <storage>::dump () const
  + 
  + namespace wi
  + {
  +-  template <>
  +   template <typename storage>
  +   struct int_traits < generic_wide_int <storage> >
  +     : public wi::int_traits <storage>
  +@@ -960,7 +952,6 @@ inline wide_int_ref_storage <SE>::wide_int_ref_storage (const T &x,
  + 
  + namespace wi
  + {
  +-  template <>
  +   template <bool SE>
  +   struct int_traits <wide_int_ref_storage <SE> >
  +   {
  +@@ -1147,7 +1138,6 @@ class GTY(()) fixed_wide_int_storage
  + 
  + namespace wi
  + {
  +-  template <>
  +   template <int N>
  +   struct int_traits < fixed_wide_int_storage <N> >
  +   {
  +
  diff --git a/tools/bison/patches/001-fix-port-gnulib.patch b/tools/bison/patches/001-fix-port-gnulib.patch
  new file mode 100644
  index 000000000000..499d73a2666d
  --- /dev/null
  +++ b/tools/bison/patches/001-fix-port-gnulib.patch
  @@ -0,0 +1,11 @@
  +--- a/lib/fseterr.c  2022-02-10 13:17:52.129083732 +0800
  ++++ b/lib/fseterr.c  2022-02-10 13:23:49.408599169 +0800
  +@@ -29,7 +29,7 @@
  +   /* Most systems provide FILE as a struct and the necessary bitmask in
  +      <stdio.h>, because they need it for implementing getc() and putc() as
  +      fast macros.  */
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   fp->_flags |= _IO_ERR_SEEN;
  + #elif defined __sferror || defined __DragonFly__ /* FreeBSD, NetBSD, OpenBSD, DragonFly, Mac OS X, Cygwin */
  +   fp_->_flags |= __SERR;
  diff --git a/tools/e2fsprogs/patches/001-fix-undefined-reference-makedev.patch b/tools/e2fsprogs/patches/001-fix-undefined-reference-makedev.patch
  new file mode 100644
  index 000000000000..2c059b4ea072
  --- /dev/null
  +++ b/tools/e2fsprogs/patches/001-fix-undefined-reference-makedev.patch
  @@ -0,0 +1,9 @@
  +--- a/lib/blkid/devname.c 2021-02-07 16:04:24.190214251 +0800
  ++++ b/lib/blkid/devname.c 2021-02-07 16:03:53.869128549 +0800
  +@@ -37,6 +37,7 @@
  + #include <sys/mkdev.h>
  + #endif
  + #include <time.h>
  ++#include <sys/sysmacros.h>
  + 
  + #include "blkidP.h"
  \ No newline at end of file
  diff --git a/tools/findutils/patches/001-fix-port-gnulib.patch b/tools/findutils/patches/001-fix-port-gnulib.patch
  new file mode 100644
  index 000000000000..f164d776ba24
  --- /dev/null
  +++ b/tools/findutils/patches/001-fix-port-gnulib.patch
  @@ -0,0 +1,33 @@
  +--- a/gnulib/lib/freadahead.c    2008-04-17 01:55:14.000000000 +0200
  ++++ b/gnulib/lib/freadahead.c    2008-04-17 01:54:36.000000000 +0200
  +@@ -22,7 +22,7 @@
  + size_t
  + freadahead (FILE *fp)
  + {
  +-#if defined _IO_ferror_unlocked     /* GNU libc, BeOS */
  ++#if defined _IO_EOF_SEEN || defined _IO_ferror_unlocked || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Linux libc5 */
  +   if (fp->_IO_write_ptr > fp->_IO_write_base)
  +     return 0;
  +   return (fp->_IO_read_end - fp->_IO_read_ptr)
  +--- a/gnulib/lib/freading.c      2008-04-17 01:55:14.000000000 +0200
  ++++ b/gnulib/lib/freading.c      2008-04-17 01:54:36.000000000 +0200
  +@@ -29,7 +29,7 @@
  +   /* Most systems provide FILE as a struct and the necessary bitmask in
  +      <stdio.h>, because they need it for implementing getc() and putc() as
  +      fast macros.  */
  +-#if defined _IO_ferror_unlocked     /* GNU libc, BeOS */
  ++#if defined _IO_EOF_SEEN || defined _IO_ferror_unlocked || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Linux libc5 */
  +   return ((fp->_flags & _IO_NO_WRITES) != 0
  +          || ((fp->_flags & (_IO_NO_READS | _IO_CURRENTLY_PUTTING)) == 0
  +              && fp->_IO_read_base != NULL));
  +--- a/gnulib/lib/fseeko.c        2008-04-17 01:55:14.000000000 +0200
  ++++ b/gnulib/lib/fseeko.c        2008-04-17 01:54:36.000000000 +0200
  +@@ -39,7 +39,7 @@
  + #endif
  + 
  +   /* These tests are based on fpurge.c.  */
  +-#if defined _IO_ferror_unlocked     /* GNU libc, BeOS */
  ++#if defined _IO_EOF_SEEN || defined _IO_ferror_unlocked || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Linux libc5 */
  +   if (fp->_IO_read_end == fp->_IO_read_ptr
  +       && fp->_IO_write_ptr == fp->_IO_write_base
  +       && fp->_IO_save_base == NULL)
  diff --git a/tools/m4/patches/200-fix-port-gnulib-freadahead.patch b/tools/m4/patches/200-fix-port-gnulib-freadahead.patch
  new file mode 100644
  index 000000000000..9501b4fc7788
  --- /dev/null
  +++ b/tools/m4/patches/200-fix-port-gnulib-freadahead.patch
  @@ -0,0 +1,109 @@
  +diff --git a/lib/fflush.c b/lib/fflush.c
  +index 983ade0ffb..a6edfa105b 100644
  +--- a/lib/fflush.c
  ++++ b/lib/fflush.c
  +@@ -33,7 +33,7 @@
  + #undef fflush
  + 
  + 
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  + 
  + /* Clear the stream's ungetc buffer, preserving the value of ftello (fp).  */
  + static void
  +@@ -72,7 +72,7 @@ clear_ungetc_buffer (FILE *fp)
  + 
  + #endif
  + 
  +-#if ! (defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */)
  ++#if ! (defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */)
  + 
  + # if (defined __sferror || defined __DragonFly__ || defined __ANDROID__) && defined __SNPT
  + /* FreeBSD, NetBSD, OpenBSD, DragonFly, Mac OS X, Cygwin, Minix 3, Android */
  +@@ -148,7 +148,7 @@ rpl_fflush (FILE *stream)
  +   if (stream == NULL || ! freading (stream))
  +     return fflush (stream);
  + 
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  + 
  +   clear_ungetc_buffer_preserving_position (stream);
  + 
  +diff --git a/lib/fpurge.c b/lib/fpurge.c
  +index b1d417c7a2..3aedcc3734 100644
  +--- a/lib/fpurge.c
  ++++ b/lib/fpurge.c
  +@@ -62,7 +62,7 @@ fpurge (FILE *fp)
  +   /* Most systems provide FILE as a struct and the necessary bitmask in
  +      <stdio.h>, because they need it for implementing getc() and putc() as
  +      fast macros.  */
  +-# if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++# if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   fp->_IO_read_end = fp->_IO_read_ptr;
  +   fp->_IO_write_ptr = fp->_IO_write_base;
  +   /* Avoid memory leak when there is an active ungetc buffer.  */
  +diff --git a/lib/freadahead.c b/lib/freadahead.c
  +index c2ecb5b28a..23ec76ee53 100644
  +--- a/lib/freadahead.c
  ++++ b/lib/freadahead.c
  +@@ -30,7 +30,7 @@ extern size_t __sreadahead (FILE *);
  + size_t
  + freadahead (FILE *fp)
  + {
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   if (fp->_IO_write_ptr > fp->_IO_write_base)
  +     return 0;
  +   return (fp->_IO_read_end - fp->_IO_read_ptr)
  +diff --git a/lib/freading.c b/lib/freading.c
  +index 73c28acddf..c24d0c88ab 100644
  +--- a/lib/freading.c
  ++++ b/lib/freading.c
  +@@ -31,7 +31,7 @@ freading (FILE *fp)
  +   /* Most systems provide FILE as a struct and the necessary bitmask in
  +      <stdio.h>, because they need it for implementing getc() and putc() as
  +      fast macros.  */
  +-# if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++# if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   return ((fp->_flags & _IO_NO_WRITES) != 0
  +           || ((fp->_flags & (_IO_NO_READS | _IO_CURRENTLY_PUTTING)) == 0
  +               && fp->_IO_read_base != NULL));
  +diff --git a/lib/fseeko.c b/lib/fseeko.c
  +index 0101ab55f7..193f4e8ce5 100644
  +--- a/lib/fseeko.c
  ++++ b/lib/fseeko.c
  +@@ -47,7 +47,7 @@ fseeko (FILE *fp, off_t offset, int whence)
  + #endif
  + 
  +   /* These tests are based on fpurge.c.  */
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   if (fp->_IO_read_end == fp->_IO_read_ptr
  +       && fp->_IO_write_ptr == fp->_IO_write_base
  +       && fp->_IO_save_base == NULL)
  +@@ -123,7 +123,7 @@ fseeko (FILE *fp, off_t offset, int whence)
  +           return -1;
  +         }
  + 
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +       fp->_flags &= ~_IO_EOF_SEEN;
  +       fp->_offset = pos;
  + #elif defined __sferror || defined __DragonFly__ || defined __ANDROID__
  +diff --git a/lib/stdio-impl.h b/lib/stdio-impl.h
  +index 78d896e9f5..05c5752a24 100644
  +--- a/lib/stdio-impl.h
  ++++ b/lib/stdio-impl.h
  +@@ -18,6 +18,12 @@
  +    the same implementation of stdio extension API, except that some fields
  +    have different naming conventions, or their access requires some casts.  */
  + 
  ++/* Glibc 2.28 made _IO_IN_BACKUP private.  For now, work around this
  ++   problem by defining it ourselves.  FIXME: Do not rely on glibc
  ++   internals.  */
  ++#if !defined _IO_IN_BACKUP && defined _IO_EOF_SEEN
  ++# define _IO_IN_BACKUP 0x100
  ++#endif
  + 
  + /* BSD stdio derived implementations.  */
  + 
  diff --git a/tools/make-ext4fs/patches/001-fix-undefined-reference-major-minor.patch b/tools/make-ext4fs/patches/001-fix-undefined-reference-major-minor.patch
  new file mode 100644
  index 000000000000..8ee8929c1416
  --- /dev/null
  +++ b/tools/make-ext4fs/patches/001-fix-undefined-reference-major-minor.patch
  @@ -0,0 +1,9 @@
  +--- a/contents.c        2021-02-07 15:37:31.463251930 +0800
  ++++ b/contents.c        2021-02-07 15:37:03.022743240 +0800
  +@@ -15,6 +15,7 @@
  +  */
  + 
  + #include <sys/stat.h>
  ++#include <sys/sysmacros.h>
  + #include <string.h>
  + #include <stdio.h>
  \ No newline at end of file
  diff --git a/tools/mtd-utils/patches/001-fix-missing-header-file-sys-sysmacros.patch b/tools/mtd-utils/patches/001-fix-missing-header-file-sys-sysmacros.patch
  new file mode 100644
  index 000000000000..d3e586803835
  --- /dev/null
  +++ b/tools/mtd-utils/patches/001-fix-missing-header-file-sys-sysmacros.patch
  @@ -0,0 +1,10 @@
  +--- a/include/common.h  2021-02-07 16:25:50.643801767 +0800
  ++++ b/include/common.h  2021-02-07 16:25:41.139803836 +0800
  +@@ -19,6 +19,7 @@
  + #ifndef __MTD_UTILS_COMMON_H__
  + #define __MTD_UTILS_COMMON_H__
  + 
  ++#include <sys/sysmacros.h>
  + #include <stdbool.h>
  + #include <stdio.h>
  + #include <stdlib.h>
  \ No newline at end of file
  diff --git a/tools/sed/patches/001-fix-port-gnulib.patch b/tools/sed/patches/001-fix-port-gnulib.patch
  new file mode 100644
  index 000000000000..a3fd8709482f
  --- /dev/null
  +++ b/tools/sed/patches/001-fix-port-gnulib.patch
  @@ -0,0 +1,11 @@
  +--- a/lib/fwriting.c     2012-09-13 14:58:19.000000000 +0800
  ++++ b/lib/fwriting.c     2022-02-10 13:28:31.221698961 +0800
  +@@ -27,7 +27,7 @@
  +   /* Most systems provide FILE as a struct and the necessary bitmask in
  +      <stdio.h>, because they need it for implementing getc() and putc() as
  +      fast macros.  */
  +-#if defined _IO_ftrylockfile || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  ++#if defined _IO_EOF_SEEN || __GNU_LIBRARY__ == 1 /* GNU libc, BeOS, Haiku, Linux libc5 */
  +   return (fp->_flags & (_IO_NO_READS | _IO_CURRENTLY_PUTTING)) != 0;
  + #elif defined __sferror || defined __DragonFly__ /* FreeBSD, NetBSD, OpenBSD, DragonFly, Mac OS X, Cygwin */
  +   return (fp_->_flags & __SWR) != 0;
  diff --git a/tools/squashfs4/Makefile b/tools/squashfs4/Makefile
  index 50b70fbe1c90..fe292de0960b 100644
  --- a/tools/squashfs4/Makefile
  +++ b/tools/squashfs4/Makefile
  @@ -24,7 +24,7 @@ define Host/Compile
   		XZ_SUPPORT=1 \
   		LZMA_XZ_SUPPORT=1 \
   		XATTR_SUPPORT= \
  -		LZMA_LIB="$(STAGING_DIR_HOST)/lib/liblzma.a" \
  +		LZMA_LIB="$(STAGING_DIR_HOST)/lib/liblzma.a -lmd" \
   		EXTRA_CFLAGS="-I$(STAGING_DIR_HOST)/include" \
   		mksquashfs unsquashfs
   endef
  diff --git a/tools/squashfs4/patches/001-fix-undefined-reference-major.patch b/tools/squashfs4/patches/001-fix-undefined-reference-major.patch
  new file mode 100644
  index 000000000000..89b065d95bff
  --- /dev/null
  +++ b/tools/squashfs4/patches/001-fix-undefined-reference-major.patch
  @@ -0,0 +1,20 @@
  +--- a/squashfs-tools/mksquashfs.c       2021-02-08 10:08:42.135709202 +0800
  ++++ b/squashfs-tools/mksquashfs.c       2021-02-08 10:09:03.263649419 +0800
  +@@ -52,6 +52,7 @@
  + #include <regex.h>
  + #include <fnmatch.h>
  + #include <sys/wait.h>
  ++#include <sys/sysmacros.h>
  + 
  + #ifndef linux
  + #ifndef __CYGWIN__
  +--- a/squashfs-tools/unsquashfs.c       2021-02-08 10:08:48.335691509 +0800
  ++++ b/squashfs-tools/unsquashfs.c       2021-02-08 10:09:24.919589603 +0800
  +@@ -30,6 +30,7 @@
  + #include "xattr.h"
  + 
  + #include <sys/types.h>
  ++#include <sys/sysmacros.h>
  + 
  + struct cache *fragment_cache, *data_cache;
  + struct queue *to_reader, *to_deflate, *to_writer, *from_writer;
  \ No newline at end of file
  
  ```

- qsdk/qca/feeds/packages/

  ```diff
  diff --git a/libs/libgpg-error/patches/020-gawk5-support.patch b/libs/libgpg-error/patches/020-gawk5-support.patch
  new file mode 100644
  index 0000000000..218d097498
  --- /dev/null
  +++ b/libs/libgpg-error/patches/020-gawk5-support.patch
  @@ -0,0 +1,124 @@
  +--- a/lang/cl/mkerrcodes.awk
  ++++ b/lang/cl/mkerrcodes.awk
  +@@ -122,7 +122,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +--- a/src/Makefile.am
  ++++ b/src/Makefile.am
  +@@ -293,7 +293,7 @@ code-from-errno.h: mkerrcodes$(EXEEXT_FOR_BUILD) Makefile
  + 
  + errnos-sym.h: Makefile mkstrtable.awk errnos.in
  + 	$(AWK) -f $(srcdir)/mkstrtable.awk -v textidx=2 -v nogettext=1 \
  +-		-v prefix=GPG_ERR_ -v namespace=errnos_ \
  ++		-v prefix=GPG_ERR_ -v pkg_namespace=errnos_ \
  + 		$(srcdir)/errnos.in >$@
  + 
  + 
  +--- a/src/Makefile.in	2022-02-10 19:51:36.848145191 +0800
  ++++ b/src/Makefile.in	2022-02-10 20:04:18.368259432 +0800
  +@@ -1018,7 +1018,7 @@
  + 
  + errnos-sym.h: Makefile mkstrtable.awk errnos.in
  + 	$(AWK) -f $(srcdir)/mkstrtable.awk -v textidx=2 -v nogettext=1 \
  +-		-v prefix=GPG_ERR_ -v namespace=errnos_ \
  ++		-v prefix=GPG_ERR_ -v pkg_namespace=errnos_ \
  + 		$(srcdir)/errnos.in >$@
  + 
  + # We depend on versioninfo.rc because that is build by config.status
  +--- a/src/mkerrcodes.awk
  ++++ b/src/mkerrcodes.awk
  +@@ -85,7 +85,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +--- a/src/mkerrcodes1.awk
  ++++ b/src/mkerrcodes1.awk
  +@@ -81,7 +81,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +--- a/src/mkerrcodes2.awk
  ++++ b/src/mkerrcodes2.awk
  +@@ -91,7 +91,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +--- a/src/mkerrnos.awk
  ++++ b/src/mkerrnos.awk
  +@@ -83,7 +83,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +--- a/src/mkstrtable.awk
  ++++ b/src/mkstrtable.awk
  +@@ -77,7 +77,7 @@
  + #
  + # The variable prefix can be used to prepend a string to each message.
  + #
  +-# The variable namespace can be used to prepend a string to each
  ++# The variable pkg_namespace can be used to prepend a string to each
  + # variable and macro name.
  + 
  + BEGIN {
  +@@ -102,7 +102,7 @@ header {
  +       print "/* The purpose of this complex string table is to produce";
  +       print "   optimal code with a minimum of relocations.  */";
  +       print "";
  +-      print "static const char " namespace "msgstr[] = ";
  ++      print "static const char " pkg_namespace "msgstr[] = ";
  +       header = 0;
  +     }
  +   else
  +@@ -110,7 +110,7 @@ header {
  + }
  + 
  + !header {
  +-  sub (/\#.+/, "");
  ++  sub (/#.+/, "");
  +   sub (/[ 	]+$/, ""); # Strip trailing space and tab characters.
  + 
  +   if (/^$/)
  +@@ -150,7 +150,7 @@ END {
  +   else
  +     print "  gettext_noop (\"" last_msgstr "\");";
  +   print "";
  +-  print "static const int " namespace "msgidx[] =";
  ++  print "static const int " pkg_namespace "msgidx[] =";
  +   print "  {";
  +   for (i = 0; i < coded_msgs; i++)
  +     print "    " pos[i] ",";
  +@@ -158,7 +158,7 @@ END {
  +   print "  };";
  +   print "";
  +   print "static GPG_ERR_INLINE int";
  +-  print namespace "msgidxof (int code)";
  ++  print pkg_namespace "msgidxof (int code)";
  +   print "{";
  +   print "  return (0 ? 0";
  + 
  
  ```

 # 编译

## 编译前的准备

首先进入qsdk源码目录，其中的目录布局和openwrt非常接近

```sh
cd qsdk
```

在配置之前将feeds中的软件包添加进来：

```sh
make package/symlinks
```

实际上是根据feeds.conf更新feeds，然后在`./packages/feeds/`目录里面创建到`./feeds/packages`中的feeds包的软链接，在这一步之后才能看见更多的软件包

## 配置QSDK

使用默认的配置作为`.config`

```sh
cp qca/configs/qsdk/ipq_open.config .config
```

接着使用菜单配置：

```sh
make menuconfig 
```

RAX3000Q自带的固件是32bit的，因此我们这里`target`选`IPQ`，`subtarget`选`IPQ50xx(32bit)`，接着直接保存为`.config`。

在现有的`.config`中添加默认配置：

```sh
make defconfig
```

接着可以进行一些个性化配置，或者备份对.config文件所作的修改，我直接跳过了：

```sh
make kernel_menuconfig # 配置内核，可选
make menuconfig # 再次配置，可选
scripts/diffconfig.sh > mydiffconfig # 备份修改到文件mydiffconfig，可选
```

## 编译

- 预下载源码

  为了提高编译效率，先下载所有依赖，并激活多线程编译（Openwrt官网这么说的，也不知道对多线程到底有没有影响）

  ```sh
  make download
  ```

- 构建toolchain

  正式编译之前要先编译toolchain，这一步中会因为编译环境的问题导致很多error产生，因此我们需要先打一些patch的

  ```sh
  make toolchain/install -j V=s
  ```

- 只构建特定软件包

  首先需要在make menuconfig中勾选该软件包，以`firewall`为例

  ```sh
  make package/network/config/firewall/compile V=s
  ```

  产物在`./bin/ipq/packages/base/firewall_2015-07-27_ipq.ipk`

- 全盘编译

  ```sh
  make -j V=s
  ```

  产生的完整img文件在`./bin/ipq/`下。

  但是我**没有尝试过将其刷入**因此**不保证不会刷坏！！！！！！**

# 编译失败的排错

[这篇文章](https://www.litreily.top/2021/02/07/qsdk-compile)里已经涵盖了很多在ubuntu20.04环境中编译时可能遇到的问题，但我在编译这一版本的QSDK时还遇到了额外的问题。所有对QSDK所需的修改已经在文章开头的diff文件中涵盖了，这里只是列出信息有助于排错：

- u-boot的编译依赖于libssl1.0-dev：

  系统的libssl-dev版本太新了，需要更换为libssl1.0-dev

- 编译squashfs4时遇到undefined reference to `SHA256Init'：

  ```txt
  /usr/bin/ld: /qsdk/qsdk/staging_dir/host/lib/liblzma.a(liblzma_la-check.o): in function `lzma_check_init':
  check.c:(.text+0x75): undefined reference to `SHA256Init'
  /usr/bin/ld: /qsdk/qsdk/staging_dir/host/lib/liblzma.a(liblzma_la-check.o): in function `lzma_check_update':
  check.c:(.text+0xbf): undefined reference to `SHA256Update'
  /usr/bin/ld: /qsdk/qsdk/staging_dir/host/lib/liblzma.a(liblzma_la-check.o): in function `lzma_check_finish':
  check.c:(.text+0x115): undefined reference to `SHA256Final'
  collect2: error: ld returned 1 exit status
  ```

  参考[这个链接](https://forums.freebsd.org/threads/binutils-gdb-linker-wont-find-_libmd_sha256_init-etc.79347/)可以了解到，这是因为宿主环境中提供`SHA256Init`这个函数的库改为了`libmd.a`，需要修改`tools/squashfs4/Makefile`，加上链接器选项`-lmd`

  ```diff
  --- a/tools/squashfs4/Makefile
  +++ b/tools/squashfs4/Makefile
  @@ -24,7 +24,7 @@ define Host/Compile
   		XZ_SUPPORT=1 \
   		LZMA_XZ_SUPPORT=1 \
   		XATTR_SUPPORT= \
  -		LZMA_LIB="$(STAGING_DIR_HOST)/lib/liblzma.a" \
  +		LZMA_LIB="$(STAGING_DIR_HOST)/lib/liblzma.a -lmd" \
   		EXTRA_CFLAGS="-I$(STAGING_DIR_HOST)/include" \
   		mksquashfs unsquashfs
   endef
  ```

- 编译gcc-5.2.0时报`gcc-5.2.0/gcc/wide-int.h:370:10: error: too many template-parameter-lists`

  修复办法参考[这里](https://gist.github.com/thierer/534faf0772ee66c51fdfcf964ebb1655)

- 编译libgpg-error时出现gawk和`namespace`相关的错误信息

  是因为宿主机器使用的gawk5.0版本过新，修复方法[参考这个patch](https://github.com/neheb/packages/blob/9afde0d39ae364c327063d36b188465058056a86/libs/libgpg-error/patches/020-gawk5-support.patch)

# 引用

- [下载安装基于 openwrt 的 QSDK - LITREILY](https://www.litreily.top/2021/01/29/qsdk/[)

- [基于 IPQ807x 编译 QSDK - LITREILY](https://www.litreily.top/2021/02/07/qsdk-compile)

- [为 SONY MANOMA NCP-HG100 构建 Dropbear（SSH 服务器）](https://nodemand.hatenablog.com/entry/2020/11/24/155129)
