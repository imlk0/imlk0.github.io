---
title: '读Android系统篇之----免root实现Hook系统服务拦截方法'
date: 2018-04-13T15:00:21+08:00
id: 35
aliases:
  - /blog/35/
categories:
  - Android
tags:
  - Android
  - Binder
  - IPC
  - 读书笔记
---

第二篇读书笔记

拜读姜维大神的[Android系统篇之----免root实现Hook系统服务拦截方法](https://blog.csdn.net/jiangwei0910410003/article/details/52523679)

梳理了下思路，解决了疑惑



我们使用剪切板服务的时候是调用了`ContextImpl`的`getSystemService`方法

#### `ContextImpl`的`getSystemService`方法

```
    @Override
    public Object getSystemService(String name) {
        return SystemServiceRegistry.getSystemService(this, name);
    }

```

该方法将返回`Object`类型对象，我们将它强制转换为一个`ClipboardManager`，也就是说它返回了一个`ClipboardManager`供我们使用。而这个方法最终将构造一个`ClipboardManager`，在`ClipboardManager`构造的过程中，将获取远端`Binder`并调用`IClipboard.Stub`的`asInterface`方法转化为**本地代理对象**保存在其中，

#### `ClipboardManager`的一个构造函数

```
    /** {@hide} */
    public ClipboardManager(Context context, Handler handler) throws ServiceNotFoundException {
        mContext = context;
        mService = IClipboard.Stub.asInterface(
                ServiceManager.getServiceOrThrow(Context.CLIPBOARD_SERVICE));
    }
```

获取远端`Binder`的操作其实是调用了`ServiceManager`中的`getService`方法，它返回的是一个远端`Binder`，实际上也就是一个`BinderProxy`（当然`ServiceManager`会把这个远端对象缓存到`sCache`中以应对频繁调用），姜维的文章里就是从这里切入，第一步先动态代理了这个`BinderProxy`。


> 这里需要铭记一点，远端`Binder`需要调用`Stub`的`asInterface`方法转化为**本地代理对象**才能使用(上面说到在`ClipboardManager`的构造函数中，这一步骤`ClipboardManager`帮我们封装了这一操作)


#### `ServiceManager`中的`getService`方法

```
    /**
     * Returns a reference to a service with the given name.
     * 
     * @param name the name of the service to get
     * @return a reference to the service, or <code>null</code> if the service doesn't exist
     */
    public static IBinder getService(String name) {
        try {
            IBinder service = sCache.get(name);
            if (service != null) {
                return service;
            } else {
                return Binder.allowBlocking(getIServiceManager().getService(name));
            }
        } catch (RemoteException e) {
            Log.e(TAG, "error in getService", e);
        }
        return null;
    }
```



下面继续解析姜维的文章中hook的流程，在上一步的动态代理之后，拦截了被代理对象（`BinderProxy`对象）的`queryLocalInterface`方法，下面是

#### `BinderProxy`中`queryLocalInterface`的实现

```
    public IInterface queryLocalInterface(String descriptor) {
        return null;
    }

```

可以看见它直接返回了`null`，而这个方法是在哪里被调用的呢，反编译`framework.jar`发现，是在`IClipboard.Stub`中，这里`IClipboard`就是用`aidl`生成的，和我们自己生成的差不多
看看

#### `IClipboard.Stub`的`asInterface`方法

```
    public static IClipboard asInterface(IBinder obj) {
        if (obj == null) {
            return null;
        }
        IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
        if (iin == null || !(iin instanceof IClipboard)) {
            return new Proxy(obj);
        }
        return (IClipboard) iin;
    }
```

回到正题，姜维的文章里拦截了`queryLocalInterface`以后，一开始我以为它又动态代理了一个叫做`base`的对象，因为这里new了一个`HookBinderInvocationHandler`，传入的第一个参数就是`base`突然有点蒙这个`base`是哪里冒出来的，看看上下文，发现是在第一个动态代理的Handler的构造函数里，传入了一个`rawBinder`，赋值给了成员变量`base`了，而这个`rawBinder`，就是第一次代理中，被代理的那个远端`Binder`，我就有点纳闷了，代理两次干啥？，仔细想，这只是个构造函数啊，我想传进去什么和我要动态代理什么对象没有关系呀。
于是翻回去看，动态代理的接口是`this.iinterface`，看了下第一次动态代理的Handler的构造函数，看到
```
this.iinterface = Class.forName("android.content.IClipboard")
```
仔细想想，这是要搞出来一个`IClipboard`啊，其实这个`IClipboard`我们前文接触过了，这里贴上`IClipboard`部分源码（主要看结构）

```
package android.content;
······
public interface IClipboard extends IInterface {

    public static abstract class Stub extends Binder implements IClipboard {
······
        private static class Proxy implements IClipboard {
······
```

梳理一遍，
第一次动态代理了远端`Binder`，Handler是`IClipboardHookBinderHandler`，
在第一次代理的Handler里面，拦截了`queryLocalInterface`方法，
这个方法是在`asInterface`里面调用的，
拦截以后，开始第二次动态代理，
用`IClipboard`这个接口合成了一个代理对象，Handler是`HookBinderInvocationHandler`，
把这个合成的代理对象`return`了！！！

没错，这里是关键，它直接把它作为`queryLocalInterface`方法的返回值`return`了

看一下原来的[BinderProxy中queryLocalInterface的实现](#BinderProxy中queryLocalInterface的实现)

再看一下[IClipboard.Stub的asInterface方法](#IClipboard.Stub的asInterface方法)

在`asInterface`方法里，我们合成的代理对象，赋值给了iin，接下来
```
        IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
        if (iin == null || !(iin instanceof IClipboard)) { //关键！！！！！
            return new Proxy(obj); //没走这！！！
        }
        return (IClipboard) iin; //走了这里，我们合成的代理对象被强制转换以后直接返回了，被用来之后进行剪切板的一些操作
```
哇，几乎哭出来，看了那么久终于懂了关键部分，为什么作者不标记一下呢
/(ㄒoㄒ)/~~

我们比较一下：

hook前：

```
[调用 getSystemService ]
 --> [ ClipboardManager 的构造函数]
 --> [间接调用了 ServiceManager 中的 getService ]
 --> [获得远端 Binder 对象]
 --> [调用 IClipboard.Stub 的 asInterface 并把远端对象传入]
 --> [获得 IClipboard.Stub.Proxy 对象]
 --> [后续使用]
```

hook后：

```
[Hook开始]
 --> [主动反射调用 ServiceManager 中的 getService 并动态代理远端对象]
 --> [正常调用开始]
 --> [调用 getSystemService ]
 --> [ ClipboardManager 的构造函数]
 --> [间接调用了 ServiceManager 中的 getService ]
 --> [获得第一次动态代理生成的对象]
 --> [调用 IClipboard.Stub 的 asInterface 并把远端对象传入]
 --> [拦截 queryLocalInterface 并合成 IClipboard 接口的代理对象]
 --> [返回合成的代理对象]
 --> [后续使用]
```


就这样，两次动态代理，第一次代理远端对象，拦截`queryLocalInterface`方法，第二次动态代理合成了一个实现了`IClipboard`接口的对象，骗过了`ClipboardManager`。

