---
title: '为ZjDroid适配ART虚拟机的尝试'
date: 2018-05-05T22:09:54+08:00
id: 42
aliases:
  - /blog/42/
categories:
  - Reverse
tags:
  - Android
  - ART
  - ZjDroid
  - 瞎搞
---
上星期趁着放假玩了玩ZjDroid，自己编译了一个来玩，最终克服万难总算找齐了源码，给编译出来了。
上一篇文章:

笔记-第一次ZjDroid脱壳实战
[https://blog.imlk.top/blog/40/](https://blog.imlk.top/blog/40/)


虽然，最终拿出来的大数字加固的dex没能恢复onCreate这个native方法（本人实在太菜），但是其他部分还是能看源码的。

### 起因
最近一个朋友给我看了一个爱加密的包，我放到模拟器里面用我的ZjDroid脱，没想到这个包却主动退出了！
我以为是检测到了ZjDroid，就卸载了ZjDroid，结果还是崩，后来上网查才发现，爱加密检测到是模拟器环境就会主动退出。

这可让我费脑筋啊！

我手上只有Android7.1.2的设备，而目前的ZjDroid只支持dalvik虚拟机上跑，这可咋办呢，要我刷机？懒得备份。。。

我记得ZjDroid的源码最后是4年前更新的，然后作者就不维护了，于是我想能不能学习ZjDroid的原理去适配art呢？

打开as就开始捣鼓了！


### 稍微尝试

尝试在Android7.1.2上面安装ZjDroid，重启，打开上次我拆的应用（就是那个我自己的应用啦）。

看log，除了几个碍眼的异常以外，没什么大状况出现，

嗯，

发送广播执行`dump_dexinfo`命令，然后一下子就崩了。

这个问题，我在上一篇文章里面就提到过了。
ZjDroid在执行`dump_dexinfo`命令的时候并没有用到native层的函数，只是通过反射获取`dalvik.system.DexFile`中的`mCookie`变量打印出来，但是发生了类型强制转换的错误，错误地把`long[]`类型转换为了`int`类型。


解决的办法是：
查阅`Android`源码，对这个`openDexFileNative`分sdk版本适配

- dalvik（Android4.4及以前 sdk <= 19）中的openDexFileNative
[http://androidxref.com/4.4.4_r1/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#301](http://androidxref.com/4.4.4_r1/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#301)

- art （Android5.1.1及以前 19 < sdk <= 22）中的openDexFileNative
[http://androidxref.com/5.1.1_r6/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#308](http://androidxref.com/5.1.1_r6/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#308)

- art （Android6.0至今(已测试7.1.2) 22 < sdk）中的openDexFileNative
[http://androidxref.com/7.1.2_r36/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#396](http://androidxref.com/7.1.2_r36/xref/libcore/dalvik/src/main/java/dalvik/system/DexFile.java#396)


### art虚拟机的mCookie

但是还有一个问题就是，
我们要的`mCookie`究竟是什么样子的呢?

通过对ZjDroid的旧版本代码进行分析发现，在dalvik虚拟机中，`mCookie`实际上就是一个结构体的内存地址，通过这个结构体可以获得内存中dex文件的地址，然后就能dump出来了。
既然如此，在art里面的`mCookie`时一个`long[]`类型的，我们就很有必要去了解这个东西是怎么形成的了。

查看Android7.1.2的源码，找到`openDexFileNative`方法的native层实现：
[http://androidxref.com/7.1.2_r36/xref/art/runtime/native/dalvik_system_DexFile.cc#156](http://androidxref.com/7.1.2_r36/xref/art/runtime/native/dalvik_system_DexFile.cc#156)

有一些情况下是返回空指针的，我们就只看返回正常值的情况，在第184-194行，
```
···
184  if (!dex_files.empty()) {
185    jlongArray array = ConvertDexFilesToJavaArray(env, oat_file, dex_files);
186    if (array == nullptr) {
187      ScopedObjectAccess soa(env);
188      for (auto& dex_file : dex_files) {
189        if (linker->FindDexCache(soa.Self(), *dex_file, true) != nullptr) {
190          dex_file.release();
191        }
192      }
193    }
194    return array;
···
```

这个`ConvertDexFilesToJavaArray`函数应该是很重要的一个函数
看看它的实现

```

77static jlongArray ConvertDexFilesToJavaArray(JNIEnv* env,
78                                             const OatFile* oat_file,
79                                             std::vector<std::unique_ptr<const DexFile>>& vec) {
80  // Add one for the oat file.
81  jlongArray long_array = env->NewLongArray(static_cast<jsize>(kDexFileIndexStart + vec.size())); //初始化一个long类型的Java数组
82  if (env->ExceptionCheck() == JNI_TRUE) {//检查是否出现异常
83    return nullptr;
84  }
85
86  jboolean is_long_data_copied;
87  jlong* long_data = env->GetLongArrayElements(long_array, &is_long_data_copied);//这里应该是获取刚刚生成的Java的long类型数组中元素的原始的指针，熟悉c语言的就知道，c中的数组是一块连续的内存结构，通过指针可以读取数组中的任意一个位置的元素
88  if (env->ExceptionCheck() == JNI_TRUE) {//检查是否出现异常
89    return nullptr;
90  }
91	// 这里的kOatFileIndex定义在了dalvik_system_DexFile.h文件中：值是0；
	// http://androidxref.com/7.1.2_r36/xref/art/runtime/native/dalvik_system_DexFile.h#25
92  long_data[kOatFileIndex] = reinterpret_cast<uintptr_t>(oat_file);//这里是c++的一种类型转换的方式，把参数转化为了uintptr_t类型，而uintptr_t类型是一种指针类型，就把它看作一个指针吧。
93  for (size_t i = 0; i < vec.size(); ++i) {//可以看到，之前在数组中第一个位置放了oat_file的地址，然后接下来从kDexFileIndexStart（这个值是1，也在上面那个文件里定义了）开始，把vec数组里面的东西填之前生成的数组里。
94    long_data[kDexFileIndexStart + i] = reinterpret_cast<uintptr_t>(vec[i].get());
95  }
96
97  env->ReleaseLongArrayElements(long_array, long_data, 0);//刷新数组信息（比如长度等）
98  if (env->ExceptionCheck() == JNI_TRUE) {//检查是否出现异常
99    return nullptr;
100  }
101
102  // Now release all the unique_ptrs.
103  for (auto& dex_file : vec) {
104    dex_file.release();
105  }
106
107  return long_array;
108}
```

可以大概了解到，第一个位置被赋值为`oat_file`这个指针（实际上就是把指向的地址存到了第一个位置里），然后依次填充`vec`这个数组里的东西到之前的`long`数组里面，看看这个`vec`：
在参数列表里：

```
std::vector<std::unique_ptr<const DexFile>>& vec
```

不要慌，看起来很复杂，但其实不难理解：

`vec`是一个引用，引用的是一个`vector`（可变长数组）对象，这个对象里装的都是`unique_ptr`类型，这也是一种指针，可以看到这个东西指向的类型是`DexFile`，上面的那段代码应该就是把这些指针指向的**地址**信息填到`long`数组里面了

最终返回的`long`类型数组里面，应该全都是地址。


### art中的DexFile

再看看`DexFile`这个东西：

在

[http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h](http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h)

```
class DexFile {
```
是一个class，里面还有结构体比如
```
  struct Header {
```
之类的，这好像和dex文件的结构有点关联了。

继续往下翻

在第1235行的地方：[http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h#1235](http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h#1235)

```
···
1234  // The base address of the memory mapping.
1235  const uint8_t* const begin_;
1236
1237  // The size of the underlying memory allocation in bytes.
1238  const size_t size_;
1239
1240  // Typically the dex file name when available, alternatively some identifying string.
1241  //
1242  // The ClassLinker will use this to match DexFiles the boot class
1243  // path to DexCache::GetLocation when loading from an image.
1244  const std::string location_;
1245
1246  const uint32_t location_checksum_;
1247
1248  // Manages the underlying memory allocation.
1249  std::unique_ptr<MemMap> mem_map_;
1250
1251  // Points to the header section.
1252  const Header* const header_;
1253
1254  // Points to the base of the string identifier list.
1255  const StringId* const string_ids_;
1256
1257  // Points to the base of the type identifier list.
1258  const TypeId* const type_ids_;
···
```

这个`begin_`的描述，似乎是什么什么内存映射的基地址，下面还有这个块区域的大小`size_`，接下来是一些指针，`Header`，`StringId`，`TypeId`啥的，结合相关代码，我猜测这就是我们要找的dex文件的信息了。


### 总结

总结一下：

Java层获取到的`mCookie`是一个`long`类型数组，里面都是地址，其中第一个地址是`oat_file`也就是oat过的文件的地址，当然现在大多数加固都不会允许虚拟机进行oat操作了，因为oat操作会在储存中生成优化过的oat文件，对于加固来说，无疑是自己把代码给出去了。这也是我们上一篇文章里，`long`数组第一个元素为0的原因：
![调试器查看内容](/images/blog/40_0.png)

解决方法：
[https://github.com/imlk0/ZjDroid/blob/master/app/src/main/java/com/android/reverse/collecter/DexFileInfoCollecter.java#L190](https://github.com/imlk0/ZjDroid/blob/master/app/src/main/java/com/android/reverse/collecter/DexFileInfoCollecter.java#L190)

接下来

我们只需要第二个位置开始的内容，每一个元素都是一个地址，把地址传到`native`方法里，在`native`层里，这个地址指向的就是一个`DexFile`类，而因为类也类似于结构体，也有它的储存结构，只要找到`begin_`和`size_`的内容就能dump出内存中的dex（odex）文件。


### 遇到的几个问题

关于内存对不到的问题：

我们知道C++和Java是有很大的区别的，在C++里面，一个变量，编译了以后，在运行时你是不能通过变量的名称来找到这个类的。因为这些变量都变成了地址或者偏移量。只代表某个内存区域。不能像Java那样通过反射动态获取。

所以，和结构体类似，想要获取一个C++对象的某个成员变量，你只能通过这个**对象的地址**+**这个成员变量在这个对象中的相对位置**来获取到，

前者我们容易得到，而后者，则需要构造一个和生成这个对象的`class`或者`struct`一模一样的`class`或者`struct`然后通过指针的形式取得其中的成员变量

看到这里可能就有人有疑问了：

- 为什么我在原始的ZjDroid源码里面看到了和Android源码里面一样的结构体定义或者class定义？
- 为什么是一模一样？


那是因为，只有一模一样，才能有一样的偏移量啊！


假设已经取得的`DexFile`的某个对象的地址`adress`(假设是`long`类型)，想获得对象中的成员变量`begin_`的值，应该用以下的步骤

```
DexFile *dexFile_ptr = (DexFile *)adress; // cast为DexFile类型的指针

dexFile_ptr -> begin_; // 这样取得begin_的内容

```

对于第一个问题：设想如果你的代码里面没有`DexFile`的定义，怎么通过编译？编译器会告诉你找不到符号

实际上第二句：
```
dexFile_ptr -> begin_;
```
可以理解为:
（`dexFile_ptr`的地址 + `begin_`这个成员变量在对象里的相对位置）就是`begin_`的内容在内存中的位置

而这个相对位置，是编译时决定的，与class的结构有关，与编译器有关，与平台有关。


### 关于C++对象的内存结构

以下是我个人所了解到的

- C++中的类如果有虚函数存在，那么对象的内存结构中第一个位置应该是**虚函数表的指针**。[https://www.linuxidc.com/Linux/2014-12/111047.htm](https://www.linuxidc.com/Linux/2014-12/111047.htm)
- C++中的函数与类绑定，在对象中不占内存
- C++中的static成员变量与类绑定，在对象中不占内存


### 挫折

发现自己编译出的so文件中`std::string`类型的大小和art虚拟机中的不一致，
[https://github.com/imlk0/ZjDroid/blob/master/app/src/main/jni/dvmnative/dexfile_art.h#L454](https://github.com/imlk0/ZjDroid/blob/master/app/src/main/jni/dvmnative/dexfile_art.h#L454)

通过dump出这一块内存经过分析可知

内存结构对应关系为：

![DexFile类的对象的内存结构](/images/blog/42_0.png)


这里的`std::string`占了3 \* 4 = 12个字节，而我编译出来的so里面，它是只占了4个字节的。

这导致，在那个string之后的内容都发生错位，也就是说，我编译出来的class，偏移量和art虚拟机里面的so文件里的不一样，这导致向ZjDroid发送`backsmali`命令无法使用


解决办法：

在一定范围内进行内存搜索：
因为`begin_`和`head_ptr`的值是一样的，我在之后的一定的内存区域内搜索`begin_`的值就能找到`head_ptr`的位置了
[https://github.com/imlk0/ZjDroid/blob/master/app/src/main/jni/dvmnative/dvmnative.cpp#L583](https://github.com/imlk0/ZjDroid/blob/master/app/src/main/jni/dvmnative/dvmnative.cpp#L583)


### 出炉

源码：
[https://github.com/imlk0/ZjDroid](https://github.com/imlk0/ZjDroid)
apk下载：
[https://github.com/imlk0/ZjDroid/releases](https://github.com/imlk0/ZjDroid/releases)


### 遗留问题

由于原始版本的源码过于老旧，似乎只适配到Android sdk 17

在高版本上部分api发生改变，会引发异常

已知：

- 应用敏感行为监控有部分功能不能使用，尤其是网络相关，比如新版Android删了`apache`的`http`库改用`Okhttp`，ZjDroid还未跟进。
- ZjDroid的`backsmali`命令虽然获取dex信息部分（native层）已经搞定，但是ZjDroid所使用的`org.jf.dexlib2`等库是四年前的版本，不支持art，要改为新版的话，要做很多修改。



欢迎提交改进


### 查看Android源码的网站

- grepcode:支持查看Android5.1.1及以前的源码，支持文件比较
[http://www.grepcode.com/](http://www.grepcode.com/)
- androidxref:资源全，但文件比较功能没上面的那个好用
[http://androidxref.com/](http://androidxref.com/)


### 参考

- 解决爱加密加固之后使用xposed hook的时候log打印不出来的问题:
[https://bbs.pediy.com/thread-216965.htm](https://bbs.pediy.com/thread-216965.htm)
- C++类对象的内存模型:
[https://www.linuxidc.com/Linux/2014-12/111047.htm](https://www.linuxidc.com/Linux/2014-12/111047.htm)
- std::string源码探秘和性能分析：
[https://blog.csdn.net/ybxuwei/article/details/51326830](https://blog.csdn.net/ybxuwei/article/details/51326830)
- 修改安卓源码：Art模式下的通用脱壳方法:
[http://www.freebuf.com/articles/terminal/166307.html](http://www.freebuf.com/articles/terminal/166307.html)
- GDB中打印ART基础类:
[http://www.cnblogs.com/YYPapa/p/6858787.html](http://www.cnblogs.com/YYPapa/p/6858787.html)
- 阿里早期Android加固代码的实现分析:
[http://www.voidcn.com/article/p-ntseiwvg-bqs.html](http://www.voidcn.com/article/p-ntseiwvg-bqs.html)
- [原创]阿里早期加固代码还原4.4-6.0:
[https://bbs.pediy.com/thread-215078.htm](https://bbs.pediy.com/thread-215078.htm)
- dex_file.h头文件
[http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h](http://androidxref.com/7.1.2_r36/xref/art/runtime/dex_file.h)
- dex_file.h头文件（Android P）
[https://android.googlesource.com/platform/art/+/android-p-preview-2/libdexfile/dex/dex_file.h](https://android.googlesource.com/platform/art/+/android-p-preview-2/libdexfile/dex/dex_file.h)
- dalvik_system_DexFile.h头文件
[http://androidxref.com/7.1.2_r36/xref/art/runtime/native/dalvik_system_DexFile.h](http://androidxref.com/7.1.2_r36/xref/art/runtime/native/dalvik_system_DexFile.h)
