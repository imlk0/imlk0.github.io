---
title: Java Thread的一些误区
id: 20
categories:
  - Java
date: 2017-12-09 16:56:54
tags:
---

## Thread

### interrupt()
>1.这个方法只会给线程设置一个为true的中断标志。
>2.该方法可在需要中断的线程内自己调用，也可在其他线程中调用需要中断的线程对象的这个方法。

> Java doc:
> 
> public void interrupt()Interrupts this thread. 
> Unless the current thread is interrupting itself, which is always permitted, the checkAccess method of this thread is invoked, which may cause a SecurityException to be thrown. 
> 
> If this thread is blocked in an invocation of the wait(), wait(long), or wait(long, int) methods of the Object class, or of the join(), join(long), join(long, int), sleep(long), or sleep(long, int), methods of this class, then its interrupt status will be cleared and it will receive an InterruptedException. 
> 
> If this thread is blocked in an I/O operation upon an InterruptibleChannel then the channel will be closed, the thread's interrupt status will be set, and the thread will receive a ClosedByInterruptException. 
> 
> If this thread is blocked in a Selector then the thread's interrupt status will be set and it will return immediately from the selection operation, possibly with a non-zero value, just as if the selector's wakeup method were invoked. 
> 
> If none of the previous conditions hold then this thread's interrupt status will be set. 
> 
> Interrupting a thread that is not alive need not have any effect.
> 
> Throws: 
> SecurityException - if the current thread cannot modify this thread 

### join()

>调用“目标Thread对象”的join方法，把当前线程加入到该对象对应的线程中，等该对象对应的线程执行完毕再执行后加入的线程。

```
public final void join()
                throws InterruptedExceptionWaits for this thread to die. 
An invocation of this method behaves in exactly the same way as the invocation 

join(0) 
Throws: 
InterruptedException - if any thread has interrupted the current thread. The interrupted status of the current thread is cleared when this exception is thrown. 
```

### static sleep()

>此方法的“调用者”所在线程进入休眠，谁调用谁睡觉。 

>与wait()的区别：
>1.sleep来自Thread类，和wait来自Object类。
>2.sleep方法没有释放锁，而wait方法释放了锁，使得其他线程可以使用同步控制块或者方法。
>3.wait，notify和notifyAll只能在同步控制方法或者同步控制块里面使用，而sleep可以在任何地方使用。

```
public static void sleep(long millis)
                  throws InterruptedExceptionCauses the currently executing thread to sleep (temporarily cease execution) for the specified number of milliseconds, subject to the precision and accuracy of system timers and schedulers. The thread does not lose ownership of any monitors.
Parameters: 
millis - the length of time to sleep in milliseconds 
Throws: 
IllegalArgumentException - if the value of millis is negative 
InterruptedException - if any thread has interrupted the current thread. The interrupted status of the current thread is cleared when this exception is thrown. 
```