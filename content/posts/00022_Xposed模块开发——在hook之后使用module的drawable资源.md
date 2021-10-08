---
title: Xposed模块开发——在hook之后使用module的drawable资源
id: 22
categories:
  - Xposed
date: 2017-12-30 16:52:36
tags:
---

在xposed开发过程中遇到了直接使用模块内置资源失效的问题，而且这个问题很诡异，有时候失效，有时候有效果，没效果的时候一般是显示一把叉叉

在上网搜索后发现，hook函数是在被hook应用内部执行的，环境不一样，所以直接用R.drawable.xxx的方式使用会出现问题。

### 解决办法：

https://forum.xda-developers.com/xposed/access-resources-module-t2805276

参考了rovo89大神在xda上面的回复，改用
```
private static String MODULE_PATH = null;
private int mFakeId = 0;

public void initZygote(StartupParam startupParam) throws Throwable {
	MODULE_PATH = startupParam.modulePath;//获取模块apk文件在储存中的位置
}

public void handleInitPackageResources(InitPackageResourcesParam resparam) throws Throwable {
	if (!resparam.packageName.equals("your.target.app"))
	return;

	XModuleResources modRes = XModuleResources.createInstance(MODULE_PATH, resparam.res);
	mFakeId = resparam.res.addResource(modRes, R.drawable.ic_launcher);
}
```
http://api.xposed.info/reference/android/content/res/XResources.html#addResource(android.content.res.Resources, int)

获得`mFakeld`变量，它储存的是在被hook应用内植入的一个假id，这个id对应的是module里面的`R.drawable.ic_launcher`这个资源，通过这个假id就可以使用到我们的module内的drawable资源。

### 再次遇到问题

在实际使用中
```
view.setBackgroundResource(mFakeId);
//导致异常
//No known package when getting value for resource number 0x7e73c7c7</pre>
```

### 再次解决

搜索到一段代码

https://github.com/neverweep/xStatusbarLunarDate/blob/master/src/de/xiaoxia/xstatusbarlunardate/Main.java

```
@Override
public void handleInitPackageResources(InitPackageResourcesParam resparam){

	if (!resparam.packageName.equals(PACKAGE_NAME))

	return; //如果不是UI则跳过

	//这里将自带的图标资源插入到systemui中，并获取到一个资源id

	XModuleResources modRes = XModuleResources.createInstance(MODULE_PATH, resparam.res); //创建一个插入资源的实例

	ic_toast_bg_fest = resparam.res.addResource(modRes, R.drawable.ic_toast_bg_fest);

	ic_toast_bg = resparam.res.addResource(modRes, R.drawable.ic_toast_bg);

}
```
使用：
```
if(_notify_icon){

	//为Toast加入背景
	
	toastView.setBackground((context.getResources().getDrawable(isFest ? ic_toast_bg_fest : ic_toast_bg)));
	
	toastView.setGravity(Gravity.CENTER);
	
	if(toastTextView != null){
	
	toastTextView.setTextColor(0xFF000000);
	
	toastTextView.setPadding(0, 15, 0, 0);
	
	toastTextView.setShadowLayer(0, 0, 0, 0X00FFFFFF);

}
```
这段代码里面使用的是配合`context`获得`drawable`，使用`setBackground()`方法

经过检验，这种写法正确。