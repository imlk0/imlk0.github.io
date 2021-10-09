---
title: 'System.loadLibrary的一二事'
date: 2021-03-08 17:10:11
id: 68
categories:
  - Android
tags:
  - Android
---

在Android应用中使用JNI时，一般会使用[`System.load(libFilePath)`](https://developer.android.com/reference/java/lang/System#load(java.lang.String))或者[`System.loadLibrary(libName)`](https://developer.android.com/reference/java/lang/System#loadLibrary(java.lang.String))来加载shared objects(.so)文件。

本文将尝试探究其中的原理，并记录一些Android中链接相关的问题。

## 如何实现

我们来看android-11.0.0_r3分支上的源码

`System.loadLibrary()`的实现如下：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:libcore/ojluni/src/main/java/java/lang/System.java;l=1663;bpv=1;bpt=1)

```java
    @CallerSensitive
    public static void loadLibrary(String libname) {
        Runtime.getRuntime().loadLibrary0(Reflection.getCallerClass(), libname);
    }
```

值得注意的是：

- `Reflection.getCallerClass()`这个函数可以获取到调用它的函数所属的类的`Class`对象，在追溯函数栈的过程中它会忽略掉所有包含`@CallerSensitive`这个注解的函数

可以看到它获取了一个`Class`对象的实例，和`libname`一起作为参数调用了`Runtime`中的方法：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:libcore/ojluni/src/main/java/java/lang/Runtime.java;l=1006;bpv=1;bpt=1)

```java
    void loadLibrary0(Class<?> fromClass, String libname) {
        ClassLoader classLoader = ClassLoader.getClassLoader(fromClass);
        loadLibrary0(classLoader, fromClass, libname);
    }
```

可以看到：

- 之前的`Class`实例被用来获取对应的`Classloader`实例

继续追踪`loadLibrary0`：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:libcore/ojluni/src/main/java/java/lang/Runtime.java;l=1051;drc=android-11.0.0_r3;bpv=1;bpt=1)

```java
    private synchronized void loadLibrary0(ClassLoader loader, Class<?> callerClass, String libname) {
		...
        String libraryName = libname;
        if (loader != null && !(loader instanceof BootClassLoader)) {
            // 查找APK中包含的.so文件，返回绝对路径
            String filename = loader.findLibrary(libraryName);
            if (filename == null &&
                    (loader.getClass() == PathClassLoader.class ||
                     loader.getClass() == DelegateLastClassLoader.class)) {
                // 如果未能在APK中找到，那么调用System.mapLibraryName()将library的名字转换为文件名，例如test转换为libtest.so，也继续尝试加载文件
                filename = System.mapLibraryName(libraryName);
            }
            if (filename == null) {
                throw new UnsatisfiedLinkError(loader + " couldn't find \"" +
                                               System.mapLibraryName(libraryName) + "\"");
            }
            // 调用nativeLoad()加载该文件
            String error = nativeLoad(filename, loader);
            if (error != null) {
                throw new UnsatisfiedLinkError(error);
            }
            return;
        }
		...
    }
```

可以发现分为两个步骤：查找.so文件路径，加载.so文件

### 查找.so文件

`loader.findLibrary()`的具体实现在`BaseDexClassLoader`中：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:libcore/dalvik/src/main/java/dalvik/system/BaseDexClassLoader.java;l=280;drc=android-11.0.0_r3;bpv=1;bpt=1)

```java
    @Override
    public String findLibrary(String name) {
        return pathList.findLibrary(name);
    }
```

它转而调用了`DexPathList`实例中的实现：

```java
    public String findLibrary(String libraryName) {
        // 将library的名字转换为文件名
        String fileName = System.mapLibraryName(libraryName);
        
        for (NativeLibraryElement element : nativeLibraryPathElements) {
            String path = element.findNativeLibrary(fileName);
            if (path != null) {
                return path;
            }
        }
        return null;
    }
```

其中的`nativeLibraryPathElements`在`DexPathList`的构造函数中产生：

```java
DexPathList(ClassLoader definingContext, String dexPath,
            String librarySearchPath, File optimizedDirectory, boolean isTrusted) {
		...
        // Native libraries may exist in both the system and
        // application library paths, and we use this search order:
        //
        //   1. This class loader's library path for application libraries (librarySearchPath):
        //   1.1. Native library directories
        //   1.2. Path to libraries in apk-files
        //   2. The VM's library path from the system property for system libraries
        //      also known as java.library.path
        //
        // This order was reversed prior to Gingerbread; see http://b/2933456.
        this.nativeLibraryDirectories = splitPaths(librarySearchPath, false);
        this.systemNativeLibraryDirectories =
                splitPaths(System.getProperty("java.library.path"), true);
        this.nativeLibraryPathElements = makePathElements(getAllNativeLibraryDirectories());
		...
    }
```

其中`getAllNativeLibraryDirectories()`的实现如下：即将`nativeLibraryDirectories`和`systemNativeLibraryDirectories`合并到一起

```java
    private List<File> getAllNativeLibraryDirectories() {
        List<File> allNativeLibraryDirectories = new ArrayList<>(nativeLibraryDirectories);
        allNativeLibraryDirectories.addAll(systemNativeLibraryDirectories);
        return allNativeLibraryDirectories;
    }
```

根据注释可以知道，会按如下顺序查找`.so`文件：

- app安装后，数据目录中存储的.so文件

- 在apk文件中查找.so文件

- 在`java.library.path`属性指定的路径中查找

  在我的设备上，这个属性指定的值为`/system/lib:/system/vendor/lib`

### 加载.so文件

找到.so文件路径后，使用`nativeLoad`函数加载：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:libcore/ojluni/src/main/java/java/lang/Runtime.java;l=1130;drc=android-11.0.0_r3;bpv=1;bpt=1)

```java
    private static String nativeLoad(String filename, ClassLoader loader) {
        return nativeLoad(filename, loader, null);
    }

    private static native String nativeLoad(String filename, ClassLoader loader, Class<?> caller);
```

对应的native函数：

```java
JNIEXPORT jstring JNICALL
Runtime_nativeLoad(JNIEnv* env, jclass ignored, jstring javaFilename,
                   jobject javaLoader, jclass caller)
{
    return JVM_NativeLoad(env, javaFilename, javaLoader, caller);
}
```

转到`JVM_NativeLoad()`：[源码链接](https://cs.android.com/android/platform/superproject/+/master:art/openjdkjvm/OpenjdkJvm.cc;drc=android-11.0.0_r3;bpv=1;bpt=1;l=321)

```cpp
JNIEXPORT jstring JVM_NativeLoad(JNIEnv* env,
                                 jstring javaFilename,
                                 jobject javaLoader,
                                 jclass caller) {
  ScopedUtfChars filename(env, javaFilename);
  if (filename.c_str() == nullptr) {
    return nullptr;
  }

  std::string error_msg;
  {
    art::JavaVMExt* vm = art::Runtime::Current()->GetJavaVM();
    bool success = vm->LoadNativeLibrary(env,
                                         filename.c_str(),
                                         javaLoader,
                                         caller,
                                         &error_msg);
    if (success) {
      return nullptr;
    }
  }

  // Don't let a pending exception from JNI_OnLoad cause a CheckJNI issue with NewStringUTF.
  env->ExceptionClear();
  return env->NewStringUTF(error_msg.c_str());
}
```

具体实现在`vm->LoadNativeLibrary()`中：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:art/runtime/jni/java_vm_ext.cc;bpv=1;bpt=1)

```cpp

bool JavaVMExt::LoadNativeLibrary(JNIEnv* env,
                                  const std::string& path,
                                  jobject class_loader,
                                  jclass caller_class,
                                  std::string* error_msg) {
  ...
  SharedLibrary* library;
  ...
    library = libraries_->Get(path);
  ...
  if (library != nullptr) {
    // 这个library已经被加载过
    if (library->GetClassLoaderAllocator() != class_loader_allocator) {
        // 如果该library已经被别的classloader加载，则返回错误信息
      ...
      std::string old_class_loader = call_to_string(library->GetClassLoader());
      std::string new_class_loader = call_to_string(class_loader);
      StringAppendF(error_msg, "Shared library \"%s\" already opened by "
          "ClassLoader %p(%s); can't open in ClassLoader %p(%s)",
          path.c_str(),
          library->GetClassLoader(),
          old_class_loader.c_str(),
          class_loader,
          new_class_loader.c_str());
      LOG(WARNING) << *error_msg;
      return false;
    }
    VLOG(jni) << "[Shared library \"" << path << "\" already loaded in "
              << " ClassLoader " << class_loader << "]";
    if (!library->CheckOnLoadResult()) {
      StringAppendF(error_msg, "JNI_OnLoad failed on a previous attempt "
          "to load \"%s\"", path.c_str());
      return false;
    }
    // 如果该library已经被当前这个classloader加载，则正常退出
    return true;
  }

  // Open the shared library.  Because we're using a full path, the system
  // doesn't have to search through LD_LIBRARY_PATH.  (It may do so to
  // resolve this library's dependencies though.)

  // Failures here are expected when java.library.path has several entries
  // and we have to hunt for the lib.

  // Below we dlopen but there is no paired dlclose, this would be necessary if we supported
  // class unloading. Libraries will only be unloaded when the reference count (incremented by
  // dlopen) becomes zero from dlclose.

  // Retrieve the library path from the classloader, if necessary.
  ScopedLocalRef<jstring> library_path(env, GetLibrarySearchPath(env, class_loader));

  Locks::mutator_lock_->AssertNotHeld(self);
  const char* path_str = path.empty() ? nullptr : path.c_str();
  bool needs_native_bridge = false;
  char* nativeloader_error_msg = nullptr;
  // 调用OpenNativeLibrary加载.so文件
  void* handle = android::OpenNativeLibrary(
      env,
      runtime_->GetTargetSdkVersion(),
      path_str,
      class_loader,
      (caller_location.empty() ? nullptr : caller_location.c_str()),
      library_path.get(),
      &needs_native_bridge,
      &nativeloader_error_msg);
  VLOG(jni) << "[Call to dlopen(\"" << path << "\", RTLD_NOW) returned " << handle << "]";

  if (handle == nullptr) { // 加载失败返回异常信息
    *error_msg = nativeloader_error_msg;
    android::NativeLoaderFreeErrorMessage(nativeloader_error_msg);
    VLOG(jni) << "dlopen(\"" << path << "\", RTLD_NOW) failed: " << *error_msg;
    return false;
  }

  if (env->ExceptionCheck() == JNI_TRUE) {
    LOG(ERROR) << "Unexpected exception:";
    env->ExceptionDescribe();
    env->ExceptionClear();
  }

  // 加载成功，将加载library得到的句柄handle封装成ShardLibrary实例，并存储到全局的libraries_中
  bool created_library = false;
  {
    std::unique_ptr<SharedLibrary> new_library(
        new SharedLibrary(env,
                          self,
                          path,
                          handle,
                          needs_native_bridge,
                          class_loader,
                          class_loader_allocator));

    MutexLock mu(self, *Locks::jni_libraries_lock_); // 加互斥锁，在出现多个线程同时加载一个.so的情况时，确保只有一个能插入
    library = libraries_->Get(path);
    if (library == nullptr) {
      library = new_library.release();
      libraries_->Put(path, library);
      created_library = true;
    }
  }
  if (!created_library) {
    // 如果没能抢到锁，那么将抢到锁的线程加载library的结果返回
    LOG(INFO) << "WOW: we lost a race to add shared library: "
        << "\"" << path << "\" ClassLoader=" << class_loader;
    return library->CheckOnLoadResult();
  }
  VLOG(jni) << "[Added shared library \"" << path << "\" for ClassLoader " << class_loader << "]";

  bool was_successful = false;
  // 从library中找到名为JNI_OnLoad的函数
  void* sym = library->FindSymbol("JNI_OnLoad", nullptr);
  if (sym == nullptr) {
    VLOG(jni) << "[No JNI_OnLoad found in \"" << path << "\"]";
    was_successful = true;
  } else {
    // 如果找到了JNI_OnLoad则调用它，并检查其返回值
	...
    JNI_OnLoadFn jni_on_load = reinterpret_cast<JNI_OnLoadFn>(sym);
    int version = (*jni_on_load)(this, nullptr);
	// 检查其返回值
    if (IsSdkVersionSetAndAtMost(runtime_->GetTargetSdkVersion(), SdkVersion::kL)) {
      EnsureFrontOfChain(SIGSEGV);
    }
	...
    if (version == JNI_ERR) {
      StringAppendF(error_msg, "JNI_ERR returned from JNI_OnLoad in \"%s\"", path.c_str());
    } else if (JavaVMExt::IsBadJniVersion(version)) {
      StringAppendF(error_msg, "Bad JNI version returned from JNI_OnLoad in \"%s\": %d",
                    path.c_str(), version);
    } else {
      was_successful = true;
    }
    VLOG(jni) << "[Returned " << (was_successful ? "successfully" : "failure")
              << " from JNI_OnLoad in \"" << path << "\"]";
  }
  library->SetResult(was_successful);
  return was_successful;
}

```

上面的代码看起来很长，实际上主要做了下面几件事：

- 检查是否已经被加载过
  - 如果加载过
    - 如果是别的ClassLoader加载的，那么返回错误
    - 否则返回正确
  - 如果没有被加载过
    - 调用`android::OpenNativeLibrary`加载
    - 加载完以后找其中是否存在`JNI_OnLoad`函数，如果找到了`JNI_OnLoad`则调用它，并检查其返回值

其中关键部分的实现在`android::OpenNativeLibrary`里：[源码链接](https://cs.android.com/android/platform/superproject/+/android-11.0.0_r3:art/libnativeloader/native_loader.cpp;l=106;drc=android-11.0.0_r3;bpv=0;bpt=1)

```cpp
void* OpenNativeLibrary(JNIEnv* env, int32_t target_sdk_version, const char* path,
                        jobject class_loader, const char* caller_location, jstring library_path,
                        bool* needs_native_bridge, char** error_msg) {
#if defined(__ANDROID__)
  UNUSED(target_sdk_version);
  if (class_loader == nullptr) {
    *needs_native_bridge = false;
    if (caller_location != nullptr) {
      android_namespace_t* boot_namespace = FindExportedNamespace(caller_location);
      if (boot_namespace != nullptr) {
        const android_dlextinfo dlextinfo = {
            .flags = ANDROID_DLEXT_USE_NAMESPACE,
            .library_namespace = boot_namespace,
        };
        void* handle = android_dlopen_ext(path, RTLD_NOW, &dlextinfo);
        if (handle == nullptr) {
          *error_msg = strdup(dlerror());
        }
        return handle;
      }
    }
    void* handle = dlopen(path, RTLD_NOW);
    if (handle == nullptr) {
      *error_msg = strdup(dlerror());
    }
    return handle;
  }

  std::lock_guard<std::mutex> guard(g_namespaces_mutex);
  NativeLoaderNamespace* ns;

  if ((ns = g_namespaces->FindNamespaceByClassLoader(env, class_loader)) == nullptr) {
    // This is the case where the classloader was not created by ApplicationLoaders
    // In this case we create an isolated not-shared namespace for it.
    Result<NativeLoaderNamespace*> isolated_ns =
        g_namespaces->Create(env, target_sdk_version, class_loader, false /* is_shared */, nullptr,
                             library_path, nullptr);
    if (!isolated_ns.ok()) {
      *error_msg = strdup(isolated_ns.error().message().c_str());
      return nullptr;
    } else {
      ns = *isolated_ns;
    }
  }

  return OpenNativeLibraryInNamespace(ns, path, needs_native_bridge, error_msg);
#else
  UNUSED(env, target_sdk_version, class_loader, caller_location);

  // Do some best effort to emulate library-path support. It will not
  // work for dependencies.
  //
  // Note: null has a special meaning and must be preserved.
  std::string c_library_path;  // Empty string by default.
  if (library_path != nullptr && path != nullptr && path[0] != '/') {
    ScopedUtfChars library_path_utf_chars(env, library_path);
    c_library_path = library_path_utf_chars.c_str();
  }

  std::vector<std::string> library_paths = base::Split(c_library_path, ":");

  for (const std::string& lib_path : library_paths) {
    *needs_native_bridge = false;
    const char* path_arg;
    std::string complete_path;
    if (path == nullptr) {
      // Preserve null.
      path_arg = nullptr;
    } else {
      complete_path = lib_path;
      if (!complete_path.empty()) {
        complete_path.append("/");
      }
      complete_path.append(path);
      path_arg = complete_path.c_str();
    }
    void* handle = dlopen(path_arg, RTLD_NOW);
    if (handle != nullptr) {
      return handle;
    }
    if (NativeBridgeIsSupported(path_arg)) {
      *needs_native_bridge = true;
      handle = NativeBridgeLoadLibrary(path_arg, RTLD_NOW);
      if (handle != nullptr) {
        return handle;
      }
      *error_msg = strdup(NativeBridgeGetError());
    } else {
      *error_msg = strdup(dlerror());
    }
  }
  return nullptr;
#endif
}

```





### 去哪查找



https://pqpo.me/2017/05/31/system-loadlibrary/



### 回调

https://stackoverflow.com/a/52553702/15011229



### 名字解析



https://stackoverflow.com/questions/20161279/jni-can-i-use-registernatives-without-calling-system-loadlibrary-for-native-pl



## 一些坑

### dependency处理

check this: https://lief.quarkslab.com/doc/latest/tutorials/09_frida_lief.html#injection-with-lief

https://stackoverflow.com/questions/17688327/android-ndk-make-two-native-shared-libraries-calling-each-other

https://stackoverflow.com/questions/12632762/android-how-to-load-shared-library

#### dlopen 如何处理链接



## 用frida hook所有native函数





