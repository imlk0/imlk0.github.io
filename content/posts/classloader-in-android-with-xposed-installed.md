---
title: '[笔记]Xposed框架加持下的Android应用ClassLoader的结构关系'
date: 2018-07-07T21:52:37+08:00
id: 43
aliases:
  - /blog/43/
categories:
  - Reverse
tags:
  - Xposed
  - Android
  - ClassLoader
---

好久没写东西了，期末终于考完了，想起之前对Xposed开发的一些问题还没有解决，于是搬出来探索了一番。

### Android应用ClassLoader再思考

我们知道，Android应用以`apk`文件的形式存在于手机储存空间之中，而要运行这些应用，则需要用ClassLoader加载到虚拟机中去。
除了应用的apk文件之外，还有一些Android框架层的类在`/system/framework/`文件夹下以`jar`包的形式存在着

![/system/framework/中的类文件](/images/blog/43_0.png)


对Android中各种类型的ClassLoader的使用的解释，网上已经已经很多了，这里就不再添乱。


### 未安装Xposed框架时的Android应用中的ClassLoader

通过调试找出了ClassLoader之间的关系（Sony z5，Android7 arm64）

![未安装Xposed框架时的Android应用中的ClassLoader关系图](/images/blog/43_1.png)

可以看到有两个`PathClassLoader`，它们的`parent`都是`BootClassLoader`。

左边那个`PathClassLoader`加载的就是我们的App，右边那个是`ClassLoader.getSystemClassLoader()`方法获取到的

#### ClassLoader.getSystemClassLoader()
翻看源码
```
    @CallerSensitive
    public static ClassLoader getSystemClassLoader() {
        return SystemClassLoader.loader;
    }
```
发现是一个静态方法
```
public abstract class ClassLoader {

    static private class SystemClassLoader {
        public static ClassLoader loader = ClassLoader.createSystemClassLoader();
    }
...
```
这个`SystemClassLoader`类是`ClassLoader`的一个静态内部类，并且静态初始化了一个`loader`成员变量
跟入`ClassLoader.createSystemClassLoader()`
```
    private static ClassLoader createSystemClassLoader() {
        String classPath = System.getProperty("java.class.path", ".");
        String librarySearchPath = System.getProperty("java.library.path", "");

        // String[] paths = classPath.split(":");
        // URL[] urls = new URL[paths.length];
        // for (int i = 0; i < paths.length; i++) {
        // try {
        // urls[i] = new URL("file://" + paths[i]);
        // }
        // catch (Exception ex) {
        // ex.printStackTrace();
        // }
        // }
        //
        // return new java.net.URLClassLoader(urls, null);

        // TODO Make this a java.net.URLClassLoader once we have those?
        return new PathClassLoader(classPath, librarySearchPath, BootClassLoader.getInstance());
    }
```
原来这个`getSystemClassLoader()`返回的`ClassLoader`就是以系统的属性构建的一个`CLassLoader`啊

在`System.initUnchangeableSystemProperties()`中找到了这个属性的初始化过程
```
    private static Properties initUnchangeableSystemProperties() {
        VMRuntime runtime = VMRuntime.getRuntime();
        Properties p = new Properties();

        // Set non-static properties.
        p.put("java.boot.class.path", runtime.bootClassPath());
        p.put("java.class.path", runtime.classPath());

        // TODO: does this make any sense? Should we just leave java.home unset?
        String javaHome = getenv("JAVA_HOME");
    ...
```

我们这里不去深究这个属性值的产生过程了，我们直接调用去获取属性，发现：
```
System.getProperty("java.class.path")="."
System.getProperty("java.library.path")="/system/lib64:/vendor/lib64"
```
看起来并没有相关的线索，上网搜也没有找到什么有价值的东西，下断点发现在应用程序启动的过程中会被被调用一次。

#### BootClassLoader

这个类加载器很特殊了，
`Integer.class.getClassLoader()`返回的就是这个`BootClassLoader`，可见这是基础的`ClassLoader`，
另外，调用`android.widget.TextView.class.getClassLoader()`得到的也是这个`BootClassLoader`

在`/init.rc`或`/init.environ.rc`中一条
```
export BOOTCLASSPATH /system/framework/org.dirtyunicorns.utils.jar
					:/system/framework/telephony-ext.jar
					:/system/framework/tcmiface.jar
					:/system/framework/core-oj.jar
					:/system/framework/core-libart.jar
					:/system/framework/conscrypt.jar
					:/system/framework/okhttp.jar
					:/system/framework/core-junit.jar
					:/system/framework/bouncycastle.jar
					:/system/framework/ext.jar
					:/system/framework/framework.jar
					:/system/framework/telephony-common.jar
					:/system/framework/voip-common.jar
					:/system/framework/ims-common.jar
					:/system/framework/apache-xml.jar
					:/system/framework/org.apache.http.legacy.boot.jar
```
从字面意思上看，应该是指定了`BootClassLoader`加载的一些系统框架类的路径，其中`android.widget.TextView`这些就是在`/system/framework/framework.jar`里的。

### Xposed框架加持以后

写过xposed模块的都知道，hook逻辑是是写在宿主app之外的独立的一个app里面的，宿主app启动的时候，这个模块app就会被启动，而在`XposedInstaller`里能控制模块app的启用或禁用。

既然要加载别的apk，那就意味着一定和ClassLoader有关系啦，
这里依然使用调试的方法，（rom：AEX Android7.1.2 arm）

![安装Xposed框架后的Android应用中的ClassLoader关系图](/images/blog/43_2.png)

可以看到刷入了Xposed框架以后发生的变化：（这里使用的是Xposed89版）

\- `BootClassLoader`的下面多了一层`PathClassLoader`
\- 宿主app的`ClassLoader`和`ClassLoader.getSystemClassLoader()`的那个一同挂在中间层下面
\- 各个模块各有独立的`PathClassLoader`加载，挂在那个`ClassLoader.getSystemClassLoader()`下面
\- `ClassLoader.getSystemClassLoader()`的加载路径里似乎多了个`/system/framework/XposedBridge.jar`

#### 中间层

把中间层里的那个dex文件pull出来解开，发现里面只有一个类
```
package xposed.dummy;

import android.content.res.Resources;

public class XResourcesSuperClass extends Resources {

}
```
这个类的作用或许要拜读Xposed的源码才能知道了，看起来和资源加载有一点关系

#### 各模块的ClassLoader

将各个模块的加载用不同的`ClassLoader`进行，避免了模块之间类的冲突，
这也意味着**模块不能直接用类似于`Class.forName()`的方式获取宿主app内的类以及成员`Member`**，
这是新手（也包括当时的我）容易犯的错误，所以Xposed提供了`XposedHelper`来提供相关操作，而且为了提高效率，内部会缓存获取到的`Member`对象。

#### ClassLoader.getSystemClassLoader()发生的变化

注意到`ClassLoader.getSystemClassLoader()`获取到的`ClassLoader`（我们姑且称之为`SystemClassLoader`吧）的路径里面多了个`/system/framework/XposedBridge.jar`

另外，执行
```
System.getProperty("java.class.path")
```
将返回`/system/framework/XposedBridge.jar`，同样的，拖出来解开看看

![/system/framework/XposedBridge.jar](/images/blog/43_3.png)
可以看到这里有Xposed开发时我们熟悉的类，也有很多我们不熟悉的类，看起来这个jar里就是Xposed在Java层的一些实现相关的东西了(。・∀・)ノ


让我们看看`de.robv.android.xposed.XposedBridge`这个我们开发时经常打交道的类是哪里加载来的
在调试时输出`de.robv.android.xposed.XposedBridge.class.getClassLoader()`的值
和`ClassLoader.getSystemClassLoader()`得到的对象进行比较，发现它们是同一个对象，就是那个`SystemClassLoader`（嘿，醒醒，只是我在这里把它这么叫而已，实际上它也是个`PathClassLoader`）


#### 小错误
我写这篇文章之前在在这里犯了一个错误，
因为对Android Studio调试时的动态执行语句的环境不是很明确，

在调试时执行`de.robv.android.xposed.XposedBridge.class.getClassLoader()`不会爆`Method threw 'java.lang.ClassNotFoundException' exception.`
然后我就以为这个`de.robv.android.xposed.XposedBridge`类应该是从app这个`PathClassLoader`向上找到的（根据双亲委托模型），但是app的`PathClassLoader`和`SystemClassLoader`没有父子关系，它们属于同一级，然后我就以为存在两个被加载的`XposedBridge.jar`。

后来发现是Android Studio太聪明了，“帮我找到”了正确的ClassLoader
如果调试时改用`loadClass`的方法或`Class.forName`都会爆异常

`Method threw 'java.lang.ClassNotFoundException' exception.`

```
getApplicationContext().getClassLoader().loadClass("de.robv.android.xposed.XposedBridge")
```
```
Class.forName("de.robv.android.xposed.XposedBridge") 
```


#### 玩坏Xposed

根据Xposed加持后的`ClassLoader`关系图可以看出，`XposedBridge.jar`被添加到了`SystemClassLoader`里面加载，那么普通应用可以获取这个`SystemClassLoader`，进而调用一些方法对自己做一些hook的操作了，能力和Xposed模块已经相当了，只是只能对自己hook而且没法像Xposed模块那样在应用启动之前就进行hook，
就我认识的有一位(nv)大(zhuang)佬突发奇想用把aide里Java显示运行输出结果的那个控制台界面hook换成了`WebView`来播放在线视频。

所以说Xposed还是很好玩的，不仅要会用，还要学会它的原理，希望有一天我也能写出有价值的东西。
