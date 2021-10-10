---
title: 'JavaScript入门啦'
date: 2018-04-17T21:19:19+08:00
id: 36
aliases:
  - /blog/36/
categories:
  - JavaScript
tags: 
  - 编程语言
---

参考资料：
ECMAScript 6 入门:
[http://es6.ruanyifeng.com/](http://es6.ruanyifeng.com/)


**以下所有代码示例均为在nodejs交互模式下进行的，环境：Linux**

- JavaScript不区分整数和浮点数，统一用Number表示;
- js注释
```JavaScript
// 注释

/*
注释
*/
```
- js等号比较运算符
```JavaScript
== // 会自动转换数据类型再比较，很多时候会得到非常诡异的结果

=== // 不会自动转换数据类型，如果数据类型不一致，直接返回false，一致的话再比较

```
- 实际时常用`===`而不用`==`
- 使用`isNaN()`函数判断是否为`NaN`
- 浮点数运算有误差
- `%`求余运算
- `node`交互模式中，`_`表示上一次语句执行成功后的结果
- `null`不等于`0`也不等于`''`
```
> null == 0
false
> null === 0
false
> null == ''
false
> null === ''
false
> null == null
true
> null === null
true
> 0 == ''
true
> 0 === ''
false
```
- js中还有一个特殊的元素`undefined`
```
> undefined === undefined
true
```
- js中`var`与不加`var`的区别：[https://www.cnblogs.com/liuna/p/6140901.html](https://www.cnblogs.com/liuna/p/6140901.html)
- js中`typeof`关键字的使用：[https://blog.csdn.net/z18842589113/article/details/53315910](https://blog.csdn.net/z18842589113/article/details/53315910)
- `typeof`运算符把类型信息当作字符串返回
```
> i = 1
1
> typeof(i)
'number'

> i = "imlk"
'imlk'
> typeof(i)
'string'

> i = true
true
> typeof(i)
'boolean'

> typeof(this)
'object'

> i = function(){
... this.console.log("imlk");
... }
[Function: i]
> typeof(i)
'function'
```
- Javascript的`delete`与C++不同，它不会删除i指向的对象，而是删除i这个属性本身。
- Javascript中的对象都有一个方法`toString()`。
- 对类型为`Function`的对象执行`toString()`方法将打印函数的内容。
```
> i = function(e){
... console.log(e)
... }
[Function: i]
> i
[Function: i]
> i.toString()
'function (e){\nconsole.log(e)\n}'
```
- js中的函数对象本身代表一个函数
- js中构造一个函数对象（函数）
```
> function f1(){};
undefined
> var f2 = function(){};
undefined
> var f3 = new Function('str','console.log(str)');//anonymous匿名函数
undefined

> f1
[Function: f1]
> f2
[Function: f2]
> f3
[Function: anonymous]

> f1.toString()
'function f1(){}'
> f2.toString()
'function (){}'
> f3.toString()
'function anonymous(str\n/*``*/) {\nconsole.log(str)\n}'

> f1.name
'f1'
> f2.name
'f2'
> f3.name
'anonymous'

> f1.prototype
f1 {}
> f2.prototype
f2 {}
> f3.prototype
anonymous {}
```
- JS所有内置对象属性和方法汇总：[https://segmentfault.com/a/1190000011467723](https://segmentfault.com/a/1190000011467723)
- JavaScript 的 valueOf() 方法，返回`对象`的`原始值`。
```
> b = new Boolean(true)
[Boolean: true]
> typeof b
'object'
> b.valueOf()
true
> typeof b.valueOf()
'boolean'

> s = new String('imlk')
[String: 'imlk']
> typeof s
'object'
> s.valueOf()
'imlk'
> typeof s.valueOf()
'string'

> n = new Number(2333)
[Number: 2333]
> typeof n
'object'
> n.valueOf()
2333
> typeof n.valueOf()
'number'
......
```
- 与`valueOf()`之相反的则是`new Object(obj)`，它将原始值转化为对应的对象
```
> a = 1;
1
> b = new Object(a)
[Number: 1]
> a == b
true
> a === b
false
```
- **js中没有类**
- js中创建对象的7种方式：[http://www.jb51.net/article/106325.htm](http://www.jb51.net/article/106325.htm)
	1.工厂模式(在函数中构造对象并返回)
	2.构造函数模式(对函数使用`new`操作符，生成的对象的`constructor`属性指向构造函数)
	3.原型模式(每一个函数都有一个`prototype`(原型)属性，它指向一个**对象**，可以理解为共享的一个对象，这个对象是与构造函数挂钩的，所有实例共享它所包含的属性和方法，注意此时所有生成的对象所访问的原型中定义的对象都是同一个东西)
	4.组合使用构造函数模式和原型模式
	5.动态原型模式
	6.寄生构造函数模式
	7.稳妥构造函数模式
- js中的对象,我们可以把ECMAScript的对象想象成散列表：无非就是一组名对值，其中值可以是数据或函数。
```
> b = {'one': 'emmm','t':23333}
{ one: 'emmm', t: 23333 }
> for (var key in b){
... console.log(key);
... console.log(b[key]);
... }
one
emmm
t
23333
undefined
```
- js的函数中有一个特殊的关键字`arguments`，因此可以支持可变长参数传递，这个`arguments`变量只可在函数中使用，是一个特殊的对象，与一个普通的对象相比，可以读取`arguments.length`属性
```
> f1 = function(e){
... console.log(typeof arguments);
... console.log(arguments.length);
... console.log(arguments);
... }
[Function: f1]
> f1(1,2);
object
2
{ '0': 1, '1': 2 }
undefined
```
- js中的`instanceof`关键字
```
> c = new f1(1,2);
object
2
{ '0': 1, '1': 2 }
f1 {}
> c.constructor
[Function: f1]
> c.constructor === f1
true
> c instanceof f1
true
```
- exports 和 module.exports 的区别
[http://cnodejs.org/topic/5231a630101e574521e45ef8](http://cnodejs.org/topic/5231a630101e574521e45ef8)
```
module.exports 初始值为一个空对象 {}
exports 是指向的 module.exports 的引用
require() 返回的是 module.exports 而不是 exports
```
- exports 快捷方式
[http://nodejs.cn/api/modules.html#modules_exports_shortcut](http://nodejs.cn/api/modules.html#modules_exports_shortcut)
`exports`变量是在模块的文件级别作用域内有效的，它在模块被执行前被赋予`module.exports`的值。
- js定义常量语法糖`const { PI }`
[https://segmentfault.com/q/1010000011190967](https://segmentfault.com/q/1010000011190967)
```
const { PI } = Math;
实际上是语法糖，等价于：
const PI = Math.PI 
```
- js模块包装器
[http://nodejs.cn/api/modules.html#modules_the_module_wrapper](http://nodejs.cn/api/modules.html#modules_the_module_wrapper)
在执行模块代码之前，Node.js 会使用一个如下的函数包装器将其包装：
```
(function(exports, require, module, __filename, __dirname) {
// 模块的代码实际上在这里
});
```
- export
模块是独立的文件，该文件内部的所有的变量外部都无法获取。如果希望获取某个变量，必须通过export输出，
```
export var firstName = 'Michael';
export var lastName = 'Jackson';
export var year = 1958;
```



