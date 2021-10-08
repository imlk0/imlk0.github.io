---
title: '[笔记]hexo模块mdjsp的开发心得'
date: 2018-04-26 22:48:26
id: 39
categories:
	- 笔记
tags:
	- 杂文
	- 笔记
---

第一次写npm插件，有点小激动，下面是写插件的坎坷之路

## 0x00 开局错误
- 在`node_modules`文件夹下新建`hexo-mdjsp-util`文件夹，
- 新建`package.json`和`index.jsp`并填好内容
```
{
  "name": "hexo-mdjsp-util",
  "version": "0.0.1",
  "main": "index",
}
```
这是网上的教程中查到的步骤依葫芦画瓢，好像没啥问题了，执行`hexo g`，我在`index.js`中只写了`console.log("mdjsp_loaded");`，但并没有看到任何输出

百度找遍了以后，遂上google
找到别人的博客：
编写Hexo插件
[http://xtutu.me/write-hexo-plugin/](http://xtutu.me/write-hexo-plugin/)

看了下原来是没在hexo中加依赖。。。


## 0x01 祸不单行
加了依赖以后：
```
...
    "hexo-renderer-marked": "^0.3.0",
    "hexo-renderer-stylus": "^0.3.1",
    "hexo-server": "^0.2.0",
    "hexo-mdjsp-util": "^0.0.1",
  }
}
...
```
执行`hexo`
直接：
```
ERROR Plugin load failed: hexo-mdjsp-util
TypeError: this.log is not a function
    at /mnt/d/hexo/node_modules/hexo-mdjsp-util/index.js:9:6
...
```
google:

Hexo：如何解决 FATAL Cannot read property 'code' of undefined：
[http://meiweiping.cn/Hexo%EF%BC%9A%E5%A6%82%E4%BD%95%E8%A7%A3%E5%86%B3-FATAL-Cannot-read-property-code-of-undefined/](http://meiweiping.cn/Hexo%EF%BC%9A%E5%A6%82%E4%BD%95%E8%A7%A3%E5%86%B3-FATAL-Cannot-read-property-code-of-undefined/)
原来是末尾多了个`,`
真恶心的错误啊


接下来的事情就是jsp语句匹配啦！
先找几个开源项目看看


