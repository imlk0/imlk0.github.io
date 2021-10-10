---
title: '理解Android中Service的Binder跨进程通信机制'
date: 2018-04-11T22:38:50+08:00
id: 31
aliases:
  - /blog/31/
categories:
  - Android
tags:
  - Android
  - Binder
  - IPC
  - 读书笔记
---

今天拜读了姜维大神的`Android系统篇之----Binder机制和远程服务调用机制分析`

[Android系统篇之----Binder机制和远程服务调用机制分析](https://blog.csdn.net/jiangwei0910410003/article/details/52467919)

读完有一个疑惑，就是
文中

> 6、最后返回的对象其实就是这个`Proxy`对象，而这个对象内部使用了静态代理方式，内部有一个来自远端的`mRemote`变量即`IBinder`对象。然后直接调用方法其实就是调用`mRemote`的`transact`方法进行通信了。


`IBinder`是一个接口，具体的实现类没有说明，一开始以为是`Binder`，看了一下`Binder`的`transact`方法实现，发现直接调用了`Stub`的`onTransact`，真是简直了，一脸懵逼啊，这不是就在自己的进程执行了嘛，`native`呢？后来上网查发现这里的`mRemote`实际上是
```
final class BinderProxy implements IBinder 
```
但在as里面搜不到这个类，于是取出`framework.jar`用jadx开，果然看到`android.os.BinderProxy`
其中有：
```
    public boolean transact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
        Binder.checkParcel(this, code, data, "Unreasonably large binder buffer");
        return transactNative(code, data, reply, flags);
    }
```

和

```
	public native boolean transactNative(int i, Parcel parcel, Parcel parcel2, int i2) throws RemoteException;
```

![jadx反编译的framework.jar](/images/blog/31_0.png)

这里`Proxy`类中的`mRemote`类型是`BinderProxy`
```
mRemote.transact(Stub.TRANSACTION_getData, _data, _reply, 0);
```
这句实际上调用了`BinderProxy`的`transact`方法，上面看到它转而调用了一个`transactNative`的native方法实现和内核通信

猜想这个因为是系统的实现，所以as里面搜不到这个类，真的是找了好久。终于明白了



**`BinderProxy`源码(Android 6.0.1)**

```
package android.os;

import android.os.IBinder.DeathRecipient;
import android.util.Log;
import java.io.FileDescriptor;
import java.lang.ref.WeakReference;

/* compiled from: Binder */
final class BinderProxy implements IBinder {
    private long mObject;
    private long mOrgue;
    private final WeakReference mSelf = new WeakReference(this);

    private final native void destroy();

    public native String getInterfaceDescriptor() throws RemoteException;

    public native boolean isBinderAlive();

    public native void linkToDeath(DeathRecipient deathRecipient, int i) throws RemoteException;

    public native boolean pingBinder();

    public native boolean transactNative(int i, Parcel parcel, Parcel parcel2, int i2) throws RemoteException;

    public native boolean unlinkToDeath(DeathRecipient deathRecipient, int i);

    public IInterface queryLocalInterface(String descriptor) {
        return null;
    }

    public boolean transact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
        Binder.checkParcel(this, code, data, "Unreasonably large binder buffer");
        return transactNative(code, data, reply, flags);
    }

    public void dump(FileDescriptor fd, String[] args) throws RemoteException {
        Parcel data = Parcel.obtain();
        Parcel reply = Parcel.obtain();
        data.writeFileDescriptor(fd);
        data.writeStringArray(args);
        try {
            transact(IBinder.DUMP_TRANSACTION, data, reply, 0);
            reply.readException();
        } finally {
            data.recycle();
            reply.recycle();
        }
    }

    public void dumpAsync(FileDescriptor fd, String[] args) throws RemoteException {
        Parcel data = Parcel.obtain();
        Parcel reply = Parcel.obtain();
        data.writeFileDescriptor(fd);
        data.writeStringArray(args);
        try {
            transact(IBinder.DUMP_TRANSACTION, data, reply, 1);
        } finally {
            data.recycle();
            reply.recycle();
        }
    }

    BinderProxy() {
    }

    protected void finalize() throws Throwable {
        try {
            destroy();
        } finally {
            super.finalize();
        }
    }

    private static final void sendDeathNotice(DeathRecipient recipient) {
        try {
            recipient.binderDied();
        } catch (RuntimeException exc) {
            Log.w("BinderNative", "Uncaught exception from death notification", exc);
        }
    }
}
```


参考：
Android系统篇之----Binder机制和远程服务调用机制分析
[https://blog.csdn.net/jiangwei0910410003/article/details/52467919](https://blog.csdn.net/jiangwei0910410003/article/details/52467919)
Android系统进程间通信Binder机制在应用程序框架层的Java接口源代码分析
[https://www.linuxidc.com/Linux/2011-07/39620p9.htm](https://www.linuxidc.com/Linux/2011-07/39620p9.htm)
