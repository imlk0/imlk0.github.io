---
title: 重拾Python之旅
id: 34
categories:
  - Python
date: 2018-01-21T00:11:50+08:00
tags:
---

```
#!/usr/bin/env python
#coding:utf-8

# http://www.he11oworld.com/course/54

# linux上必须写 #!/usr/bin/env python 它能够引导程序找到python的解析器，也就是说，不管你这个文件保存在什么地方，这个程序都能执行，而不用制定Python的安装路径。
# 如果是Windows操作系统，则不必写。
# #coding:utf-8

# #单行注释
# 
# '''
# 多行注释
# '''
# 
# """
# 或多行注释
# """

# python3:

python支持&|^位运算

# bool运算符
and #&&
or #||
not #!

3//2	#1		直接去掉小数
3/2		#1.5	不管是否整除都输出小数
4/2		#1.0
2**8	#256
# python没有++和--

type(10**100)
#<type 'long'>	py2
#<class 'int'>	py3
#两个版本有区别，在Python 3中，不再有long类型对象了，都归类为int类型。

id(233)
# Help on built-in function id in module builtins:

# id(obj, /)
#     Return the identity of an object.

#     This is guaranteed to be unique among simultaneously existing objects.
#     (CPython uses the object's memory address.)

# 除了使用%求余数，还有内建函数divmod()——返回的是商和余数。
divmod(5, 2)	#表示5除以2，返回了商和余数
# (2, 1)
divmod(9, 2)
# (4, 1)
divmod(5.0, 2)
# (2.0, 1.0)
# Help on built-in function divmod in module builtins:

# divmod(x, y, /)
#     Return the tuple (x//y, x%y).  Invariant: div*y + mod == x.

# round
# adj. 	圆形的; 弧形的; 丰满的，肥胖的; 整数的;
# adv. 	到处; 在周围; 迂回地; 朝反方向;
# prep. 	大约; 绕过，环绕; （表示位置） 在…四周; 附近;
round(1.22222,2)	#四舍五入，但有时由于十进制转二进制的问题导致结果不准确
#1.22
round(2.235, 2)
# 2.23                #应该是：2.24
# Help on built-in function round in module builtins:

# round(...)
#     round(number[, ndigits]) -> number

#     Round a number to a given precision in decimal digits (default 0 digits).
#     This returns an int when called with one argument, otherwise the
#     same type as the number. ndigits may be negative.

math.pow(4, 2)
# 16
#	math.pow(x,y)等价于x ** y
# Help on built-in function pow in module builtins:

# pow(x, y, z=None, /)
#     Equivalent to x**y (with two arguments) or x**y % z (with three arguments)

#     Some types, such as ints, are able to use a more efficient algorithm when
#     invoked using the three argument form.

print("123\b123")#'\b'等于backspace键，会在光标处删去一个字符并前移
#12123
print("123\000123")
#123 123
# 转义字符描述
# \(在行尾时) 续行符
# \反斜杠符号
# \'单引号
# \"双引号
# \a响铃
# \b退格(Backspace)
# \e转义
# \000空
# \n换行
# \v纵向制表符
# \t横向制表符
# \r回车
# \f换页
# \oyy八进制数，yy代表的字符，例如：\o12代表换行
# \xyy十六进制数，yy代表的字符，例如：\x0a代表换行
# \other其它的字符以普通格式输出，如\q输出\q

# str类型切片[x:y:z]	z步长,z不可为0,z不写默认为1
lang = "012345678"
# 从x开始以z为步长,满足在x与y直接且不等于y的位置的所有元素
lang[:1]
# '0'
# 若什么都没截取到，返回 ''
lang[:0]
# ''
lang[:9]
# '012345678'
# 若x或y的值为正数或零，则“边界指针”从字符串的左边数起，
# 若为负数，则先按绝对值从右边数起转换为对应的正数
lang = "012345678"
# 		012345678 正数索引
# 		-9-8-7-6-5-4-3-2-1 负数索引
# 当x或者y不写时,看z,
# 若z为正,则x默认为0,y默认为总长度,
# 若z为负,则y默认为 -1 (不转换为正数),x默认为 总长度 - 1.
lang[-1:]	# == lang[8:]
# '8'
lang[:-1]	# == lang[:8]
# '01234567'
lang[1:7:2]
# '135'
lang[1:7:-2]
# ''
lang[7:1:-2]
# '753'
lang[:7:2]	# == lang[0:7:2]
# '0246'
lang[:5:-2]
# '86'
lang[-1::-2]	#== lang[8::-2]
# '86420'

ord('a')
# 97	#'a'的Unicode码(与ascii一致)
ord(' ')
# 32	#' '的Unicode码(与ascii一致)
# Help on built-in function ord in module builtins:

# ord(c, /)
#     Return the Unicode code point for a one-character string.

chr(97)
# 'a'
# Help on built-in function chr in module builtins:

# chr(i, /)
#     Return a Unicode string of one character with ordinal i; 0 <= i <= 0x10ffff.

cmp()
# py3取消了 cmp() 内建函数，改用 > < ==比较字符串

# is == 的区别
# is比较的是id，比较判断的是对象间的唯一身份标识
# ==比较的是值value是否相等，取决于__eq__()

#关于 bool 类型
# python 没有 ! 运算符，改用 not 运算符，对 bool 类型取反
!True
#   File "<stdin>", line 1
#     !True
#     ^
# SyntaxError: invalid syntax
not True
# False

# 在python中 None,  False, 空字符串"", 0, 空列表[], 空字典{}, 空元组()都相当于False

# 格式化字符串 %
"I like %s" % "python"
# 'I like python'
"%s like %s" % ("imlk","python")
# 'imlk like python'
# 多个参数时使用 tuple (元组)
"%(name)s like %(what)s" % {'name':'imlk', 'what':'python'}
# 'imlk like python'
# "%(name)s like %(what)s" % {'name':'imlk', 'what':'python'}
#		  ^				^
# 配合字典使用注意标注参数类型

# 格式化字符串 format
# 占位符
# {[序号或唯一标识符][若该占位符参数为列表,此处可索引列表中元素,如[1]]:[填充字符][对齐方式 <^>(<是字符默认,>是整数和浮点数默认)][宽度][.n若明确参数类型f,则表示小数点后精度n,若不明确,对于str,截取前n个字符,对于浮点型,用科学记数法表示并把e以前的数字个数限制为n个][参数类型,如f,d,b二进制,o八进制,x十六进制]}
"{} like {}" .format("imlk","python")
# 'imlk like python'
"{1} like {0}" .format("python","imlk")#指定序号
# 'imlk like python'
"{name}s like {what}" .format(name ='imlk', what='python')#这样写,函数内部得到的是一个字典{'name':'imlk', 'what':'python'}
# 'imlks like python'
'{0[0]} like {0[1]}'.format(l)
# 'imlk like python'
'{:20}'.format(111)
# '                 111'
'{:20}'.format(111.0)
# '               111.0'
'{:20}'.format('111')
# '111                 '
'{:20.2}'.format(111.0)
# '             1.1e+02'
'{:20.3}'.format(111.1111)
# '            1.11e+02'
'{:20.2f}'.format(111.1111)
# '              111.11'
'{:20.4}'.format('111.1111')
# '111\.                '

# Help on method_descriptor:

# format(...)
#     S.format(*args, **kwargs) -> str

#     Return a formatted version of S, using substitutions from args and kwargs.
#     The substitutions are identified by braces ('{' and '}').

# 可变长度函数参数
# *args 表示任何多个无名参数，它是一个 tuple (元组)
# **kwargs 表示关键字参数，它是一个dict,字典中的 key 是传入参数的名称的 字符串 ,value 是传入参数等号后的值
# 同时使用*args和**kwargs时，必须*args参数列要在**kwargs前

# 可将元组作为参数列表传入
# 例如:
t = ("python","imlk")
"{1} like {0}" .format(*t)	# *接元组表示把元组解开作为参数传入
# 'imlk like python'
# 同理可将字典作为参数列表传入
# 例如:
d = {'name':'imlk', 'what':'python'}
"{name} like {what}" .format(**d)# **接字典表示把字典解开作为参数传入
# 'imlk like python'

# 参考:
# https://www.cnblogs.com/fengmk2/archive/2008/04/21/1163766.html
# https://www.cnblogs.com/benric/p/4965224.html

# 去除字符串两端的空格,返回去除后的字符串,源串不变,同类有lstrip()左,rstrip()右
# str.strip()
# Help on method_descriptor:

# strip(...)
#     S.strip([chars]) -> str

#     Return a copy of the string S with leading and trailing
#     whitespace removed.
#     If chars is given and not None, remove characters in chars instead.

# [] list 列表
# 类型不限 元素类型可异 有序 元素可重复 内容可变(原地改变,id不变)(append,insert,pop,extend等) 不可做为dic的key
list = [1,'233','imlk',True]
bool(list)	#判断是否空列表若列表为空则返回False
int(list)	#不合法！！！！！

# 长度
len(list)

# +，连接两个序列
# *，重复列表中的所有元素
# in 判断是否在列表中

# 最大最小
max(list)
min(list)

# 列表比较
# 同 str 中一样 cmp()在py3已经废弃,改用 < == >
# 按元素序号从左到右依次比较,若遇到类型不符则报错
list1 = [1,2]
list2 = [1,1]
list1 < list2
# False
list2 = [1,'1']
list1 < list2
# Traceback (most recent call last):
#   File "<stdin>", line 1, in <module>
# TypeError: unorderable types: int() < str()
list2 = [2,'1']
list1 < list2
# True

# 列表反转
list[::-1]
# 或
reversed(list)#返回一个迭代器

# list 中的每一个位置实际上维护的是对对象的引用
l
# ['imlk', 'python']
l.append(l)
l
# ['imlk', 'python', [...]]
l[2]
# ['imlk', 'python', [...]]
l[2]
# ['imlk', 'python', [...]]
l[2][2][2][2]
# ['imlk', 'python', [...]]
li = ['emmmm']
l.append(li)
l
# ['imlk', 'python', [...], ['emmmm']]
li.append('233')
l
# ['imlk', 'python', [...], ['emmmm', '233']]
l.extend(l)	#将一共可迭代的对象的全体内容加到该列表中
l
# ['imlk', 'python', [...], ['emmmm', '233'], 'imlk', 'python', [...], ['emmmm', '233']]
# Help on method_descriptor:

# extend(...)
#     L.extend(iterable) -> None -- extend list by appending elements from the iterable

l.count('imlk')	#找出某个元素出现的次数
# 2

# attribute
# vt.	认为…是; 把…归于; 把…品质归于某人; 认为某事[物]属于某人[物];
# n.	属性; （人或物的） 特征; 价值; [语法学] 定语;
hasattr(lang, '__iter__')
# 判断某个类或者对象,模块(module)是否有某种属性,函数
# Help on built-in function hasattr in module builtins:

# hasattr(obj, name, /)
#     Return whether the object has an attribute with the given name.

#     This is done by calling getattr(obj, name) and catching AttributeError.

# 查看语言保留字
import keyword
keyword.kwlist

# whitespace
# 网络 	空白符; 空白字符; 空格; 白空格; 白空间;
# separator
# n. 	分离器，分离装置; 防胀器; 
s = "I am, writing\npython\tbook on line" #这个字符串中有空格，逗号，换行\n，tab缩进\t 符号
print s #输出之后的样式
# I am, writing
# python book on line
s.split() #用split(),但是括号中不输入任何参数
# ['I', 'am,', 'writing', 'python', 'book', 'on', 'line']
# 如果split()不输入任何参数，显示就是见到任何空白符号，就用其分割了。

# Help on method_descriptor:

# split(...)
#     S.split(sep=None, maxsplit=-1) -> list of strings

#     Return a list of the words in S, using sep as the
#     delimiter string.  If maxsplit is given, at most maxsplit
#     splits are done. If sep is not specified or is None, any
#     whitespace string is a separator and empty strings are
#     removed from the result.

# () tuple 元组
# 类型不限 元素类型可异 有序 长度不可变 元素可重复 速度快 相当于常量 可以作为dic的key 可用在字符串的格式化中
t = 1,"23",[123,"abc"],("python","learn")   #元素多样性，近list
t
# (1, '23', [123, 'abc'], ('python', 'learn'))
# 元组中只有一个元素时，应该加上逗号,以免造成误解	
t = (3)
type(t)
# <class 'int'>
t = (3,)
type(t)
# <class 'tuple'>

# {} dict 字典
# 键/值对 原地修改 key不可重复 内容可变 键key必须是不可改变的数据类型，值value可以是任意类型
d = {}
# 利用元组建构字典
name = (["first", "Google"], ["second", "Yahoo"])
website = dict(name)
website
# {'second': 'Yahoo', 'first': 'Google'}
# 增加键值对
d['name'] = 'imlk'
d
# {'name': 'imlk'}
# 删除键值对
del d['name']
# 清空dict
d.clear()
d
# {}
# 检查字典中是否含有某个key
'name' in d
# False
d['name'] = 'imlk'
# 通过key获取字典中的value
d['name']
'imlk'
# 或者
d.get('name')	#若不存在则返回None
# Help on method_descriptor:

# get(...)
#     D.get(k[,d]) -> D[k] if k in D, else d.  d defaults to None.

# Help on method_descriptor:

# setdefault(...)
#     D.setdefault(k[,d]) -> D.get(k,d), also set D[k]=d if k not in D

# Python只存储基本类型的数据，比如int、str，对于不是基础类型的，比如刚才字典的值是列表，Python不会在被复制的那个对象中重新存储，而是用引用的方式，指向原来的值。
# 可变集合都是unhashable类型的。

# 数据类型的拷贝
l = ['imlk','python']
li = l.copy() #list,dict支持copy，tuple不支持
(1,).copy()
# Traceback (most recent call last):
#   File "<stdin>", line 1, in <module>
# AttributeError: 'tuple' object has no attribute 'copy'

# 深拷贝
import copy
li = copy.deepcopy(l)

# set([]) 集合 元素必须是hashable的(不能含有list dict set等。。。) 元素类型可异 不可重复 无序，不可索引，内容可变(unhashable) 原地修改
# {} #代表空字典，要建立空集合，不得不使用set()。

# frozenset([]) 不可变集合 与 set([]) 区别是hashable，不可变

# 集合运算
a = set('python')
b = set('python3')
a
# {'y', 't', 'h', 'p', 'o', 'n'}
b
# {'y', 't', '3', 'h', 'p', 'o', 'n'}
# 集合相等
a == b
# False
# 子集
a < b
# True
# 超集
a > b
# False
# 并集
a | b
# {'y', 't', '3', 'h', 'p', 'o', 'n'}
# 交集
a & b
# {'y', 't', 'h', 'p', 'o', 'n'}
# A相对B的差（补）
a - b
# set()
b - a
# {'3'}

print()
# Help on built-in function print in module builtins:

# print(...)
#     print(value, ..., sep=' ', end='\n', file=sys.stdout, flush=False)

#     Prints the values to a stream, or to sys.stdout by default.
#     Optional keyword arguments:
#     file:  a file-like object (stream); defaults to the current sys.stdout.
#     sep:   string inserted between values, default a space.
#     end:   string appended after the last value, default a newline.
#     flush: whether to forcibly flush the stream.

```
