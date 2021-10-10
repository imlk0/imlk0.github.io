---
title: '[write up] meowgame2021'
date: 2021-03-16T23:20:16+08:00
id: 69
aliases:
  - /blog/69/
categories:
    - CTF
tags:
    - meowgame
    - misc
---

# problem1

## 题目

[https://miaotony.xyz/2021/02/12/CTF_2021HappyChineseNewYear/](https://miaotony.xyz/2021/02/12/CTF_2021HappyChineseNewYear/)

## **分离文件**

下载原图后发现文件头为jpg文件头，jpg文件以`FF D8`开始以`FF D9`结束

其中隐藏的第二个文件偏移量为0x10764，我们用dd命令取出第二个文件

```bash
dd if=sleep_fix.jpg of=second_fix.rar skip=67428 bs=1
```

第二个文件的魔术字和rar文件的一致，但是分析其余字段发现并不符合rar文件格式。实质上这是一个修改了魔术字的zip文件，需要将它的魔术字修改回去。

## **压缩包密码**

直接vscode文本方式打开zip文件，可以看见末尾追加了这样的字符串：

```
喵喵说这题要足够白给，但是需要一点信息收集能力。
喵喵博客上有个面基页面，密码就设为那个页面的 url 好了。
噢格式啊，包含 https 以及结尾的 /
期待有机会能和大佬面基喵~JustTryT0F1ndM3
```

从喵喵的博客上找到了这个url，那么密码就是`https://miaotony.xyz/meetups/`

## 压缩包中的**cowsay.txt**

内容是

```
 _________________________________________
/ 8J+QruW5tOWkp+WQiS4yMDIxLm1pYW90b255Lnh \
| 5egpNaWFvVG9ueSBsaWtlcyB0byBoaWRlIHNlY3 |
| JldHMgaW4gZG9tYWlucy4KU28gd2hhdCBpcyB0a |
\ GlzPyA=                                 /
 -----------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

提取出base64内容：

```
8J+QruW5tOWkp+WQiS4yMDIxLm1pYW90b255Lnh5egpNaWFvVG9ueSBsaWtlcyB0byBoaWRlIHNlY3JldHMgaW4gZG9tYWlucy4KU28gd2hhdCBpcyB0aGlzPyA=
```

解码结果：

```
🐮年大吉.2021.miaotony.xyz
MiaoTony likes to hide secrets in domains.
So what is this?
```

## **关于xn--**

[https://stackoverflow.com/questions/9724379/xn-on-domain-what-it-means](https://stackoverflow.com/questions/9724379/xn-on-domain-what-it-means)

大概是域名中一些unicode编码的字符需要转化为xn--开头的纯ASCII表示，这两者之间有个映射关系，浏览器在访问这一类域名的时候，自动为我们做了这个转换

## **dns**

既然提到了邮件，又提到了字符画，那自然是TXT了，dig的时候记得加`+trace`（顺便骂一下google的在线dns lookup服务`https://dns.google.com/`，什么鸟东西都查不出来）

```bash
dig 'xn--9prx2jk6eno80c.2021.miaotony.xyz' TXT +noidnin +noidnout +trace
```

结果里面是这个

```
"K5XXOIJAJF2CO4ZAORUW2ZJAORXSA43IN53SA5DIMUQGM2LSON2CAZTMMFTSCCRAEAQCAIBAEAQCAIBAEAQF6IBAEAQCAIBAEAQCAIBAEAQCAIBAEBPV6IC7EAQCAXZAEBPSAIC7EAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAL5PV6IBAEAQCAIBAEAQCAIC7L4QCAIC7L4QF6X27L5PSAIBAEBPV6X27EAQCAIBAEAQF6XZ" "AEAQAUIBAL4QF6XZAL5PV6IBAFBPSSIBAL5PSAXZAEAQF6X27EAQCAIBPEAXXYID4EB6CA7D4EB6HYID4EAQCAXZAL5PSAIBAL4QF6XZAEAQF6IBAEBPSAIBAEAQCALZAL4QFYIC7L4QCAX27EAQCAXBALQQC6IBPPRPV6XZAF4QCAIBPEBPV6IC4EAQF6IC7L5OCAXBAEAFCA7BAE5PSAYBAL4QFYID4EB6CALZAL5QCA7BAF4QF6IC4EAQHYI" "D4EB6CA7C7PQQHY7BAPR6CA7C7EB6CAJ27EBOCA7BAE5PSAXBAPQQHYID4EB6CAIBAEB6CA7BAPQQHYXBALQXSALZAEAQCAXBAKYQC6IBAEB6F6IC4EAQC6IBPEBPWAID4PQQCOX27PR6CA7BABIQHYID4EB6CA7BAPQQHY7BAPR6CAKC7PQQHY7BAFBPSSID4HQQDYIBAPQQCAXZAEB6HYX27EAQCAX34PQQHYXZJEB6HYID4L4USA7D4EB6F6" "7BAPQQCAIBAPQQHYX34EB6CAPRAEA6CAIBAEAQCA7BAPQQCAIC7L5PSSID4PQQHYIBIL56CA7D4EB6CAIBAEA7CAPQKEB6F67BAPRPXYID4L56HYX34EBOF6XZML56CAXC7L5PS6IBAPQQHYID4L56CA7C7PQQCAID4L56CAID4EAXF6XZPEB6CALS7L4XSAIC4L5PSYID4L5PV6X27LRPV6XZPEAXV6L24L5OF6X27L5PXYX34EAQHYX27L5PS" "6IBALQQFYX27FRPXY7C7PQQCAID4EB6CACRAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBALRPVYIBAEAQCAIBAEAQCAIBAEAQCA7C7PQQCAIBAPRPXYIBAEAQCA7C7L5PS67C7L5PV6X34EAQCAIBAEAQCAIBAPRPV6X27L56CAIBAEAQCAIBAEAQCAIBALRPV6X27F4QCAIBAEAQC6XZPEAQAUTTFPB2DUIDNMVXXOZ3BNVS" "S4MRQGIYS43LJMFXXI33OPEXHQ6L2"
```

按照每8个分组后发现有很多重复的`EAQCAIBA`以此在google上搜索发现与base32相关。

当然也可以用[CyberChef](https://gchq.github.io/CyberChef/)这个工具快速找出字符串是使用了什么处理方法。

是base32！

```bash
echo 'K5XXOIJAJF2CO4ZAORUW2ZJAORXSA43IN53SA5DIMUQGM2LSON2CAZTMMFTSCCRAEAQCAIBAEAQCAIBAEAQF6IBAEAQCAIBAEAQCAIBAEAQCAIBAEBPV6IC7EAQCAXZAEBPSAIC7EAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAL5PV6IBAEAQCAIBAEAQCAIC7L4QCAIC7L4QF6X27L5PSAIBAEBPV6X27EAQCAIBAEAQF6XZAEAQAUIBAL4QF6XZAL5PV6IBAFBPSSIBAL5PSAXZAEAQF6X27EAQCAIBPEAXXYID4EB6CA7D4EB6HYID4EAQCAXZAL5PSAIBAL4QF6XZAEAQF6IBAEBPSAIBAEAQCALZAL4QFYIC7L4QCAX27EAQCAXBALQQC6IBPPRPV6XZAF4QCAIBPEBPV6IC4EAQF6IC7L5OCAXBAEAFCA7BAE5PSAYBAL4QFYID4EB6CALZAL5QCA7BAF4QF6IC4EAQHYID4EB6CA7C7PQQHY7BAPR6CA7C7EB6CAJ27EBOCA7BAE5PSAXBAPQQHYID4EB6CAIBAEB6CA7BAPQQHYXBALQXSALZAEAQCAXBAKYQC6IBAEB6F6IC4EAQC6IBPEBPWAID4PQQCOX27PR6CA7BABIQHYID4EB6CA7BAPQQHY7BAPR6CAKC7PQQHY7BAFBPSSID4HQQDYIBAPQQCAXZAEB6HYX27EAQCAX34PQQHYXZJEB6HYID4L4USA7D4EB6F67BAPQQCAIBAPQQHYX34EB6CAPRAEA6CAIBAEAQCA7BAPQQCAIC7L5PSSID4PQQHYIBIL56CA7D4EB6CAIBAEA7CAPQKEB6F67BAPRPXYID4L56HYX34EBOF6XZML56CAXC7L5PS6IBAPQQHYID4L56CA7C7PQQCAID4L56CAID4EAXF6XZPEB6CALS7L4XSAIC4L5PSYID4L5PV6X27LRPV6XZPEAXV6L24L5OF6X27L5PXYX34EAQHYX27L5PS6IBALQQFYX27FRPXY7C7PQQCAID4EB6CACRAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBALRPVYIBAEAQCAIBAEAQCAIBAEAQCA7C7PQQCAIBAPRPXYIBAEAQCA7C7L5PS67C7L5PV6X34EAQCAIBAEAQCAIBAPRPV6X27L56CAIBAEAQCAIBAEAQCAIBALRPV6X27F4QCAIBAEAQC6XZPEAQAUTTFPB2DUIDNMVXXOZ3BNVSS4MRQGIYS43LJMFXXI33OPEXHQ6L2' | base32 -d
```

结果

```
Wow! It's time to show the first flag!
             _                  __ _   _  _  _                              ___           __   __ _____    ____       __
  _ __ ___  (_)  __ _   ___    / /| | | || || |   _ __   _ __   _   _      / _ \ __  __   \ \ / /|___ /   / __ \  _ __\ \
 | '_ ` _ \ | | / _` | / _ \  | | | |_| || || |_ | '_ \ | '_ \ | | | |    | | | |\ \/ /    \ V /   |_ \  / / _` || '__|| |
 | | | | | || || (_| || (_) |< <  |  _  ||__   _|| |_) || |_) || |_| |    | |_| | >  <      | |   ___) || | (_| || |    > >
 |_| |_| |_||_| \__,_| \___/  | | |_| |_|   |_|  | .__/ | .__/  \__, |_____\___/ /_/\_\_____|_|  |____/  \ \__,_||_|   | |
                               \_\               |_|    |_|     |___/|_____|          |_____|             \____/      /_/
Next: meowgame.2021.miaotony.xyz
```

flag是`miao{H4ppy_0x_Y3@r}`

# problem2

## 题目

> #闯关 #MeowGame
Task 2
喵喵说要开个喵喵电（视）台，先播个 Pusheen 好了。
噫 jiamu 说他有好康的不如来播一下，而且还有个 secret 要给喵喵，但是藏起来了。
太坏了惹！
「jiamu 说的 secret 是不是藏在这张图里呢？」正在剪辑节目的喵喵顺手截了张图。
音视频： [https://radio.miaotony.xyz/live/2021.m3u8](https://radio.miaotony.xyz/live/2021.m3u8)
仅音频： [https://radio.miaotony.xyz/live/2021audio.m3u8](https://radio.miaotony.xyz/live/2021audio.m3u8)
（小服务器性能比较辣鸡，可能会有点卡，但视频并不必要，只听音频就能解
Hint: 后面某步可能可以找到多种脚本，如果您也是这么做的话，这题用的是名称大小写完全匹配的那个，或者自己撸代码也行（

题目中喵喵的截图：

![task.png](/images/blog/69/task.png)


## 音频

下载音频：

```bash
ffmpeg -i https://radio.miaotony.xyz/live/2021audio_360p878kbs/index.m3u8 -codec copy out_360p_878kbs_new_with_proxy.flv
```

下载一段时间后ctrl-c掐掉，发现推的是循环播放一段音频。截取出了其中重复的那部分：`cut_hq.wav` 可以在这里下载：[cut_hq.wav](/objects/meowgame2021_task2_cut_hq.wav)

经过喵喵提点，这是`SSTV`编码后的音频，用下载qssstv后，解码该文件，共识别出两张图片：

![R36_20210307_063335.png](/images/blog/69/R36_20210307_063335.png)

![M1_20210307_063355.png](/images/blog/69/M1_20210307_063355.png)

唔，是盲水印，其中提到的工具链接在这：[https://github.com/fire-keeper/BlindWatermark](https://github.com/fire-keeper/BlindWatermark)

## 盲水印

所谓的秘密就在题目中那张截图里面了：

首先剪裁图片得到其中的图片内容部分，然后使用该工具反解出盲水印。

需要注意的是该工具反解时，需要加上水印后的图片和原图一样尺寸大小。上面提到的牛年闯关入口原图大小是1280*843。截取后得到的图片如下：

![task_resize.png](/images/blog/69/task_resize.png)


使用下面的命令提取水印：

```bash
python ./bwm.py -k 2021 2333 28 -ex -r ../task_resize.png -ws 111 111 -o out_wm.png
```

发现被隐藏的内容是一个二维码：

![out_wm.png](/images/blog/69/out_wm.png)

识别出来后就是flag：`Meow~ miao{s5Tv+Bl1ndW4t3rm@rk_S0_gr3a7}`

# problem3

## 题目

> #闯关 #MeowGame
Task 3
Jiamu 说他之前的活干完了，调试用的远程服务器已经弃用了，不过正好顺便就帮喵喵藏了一个 secret。给喵喵发来了个带有 .ssh 文件夹的东西。
「jiamu 发的什么玩意啊？影响我开发 MeowGame 平台了！好烦啊！」随手就用 git 的某个魔法功能把当前修改给整没了。
「啊怎么又发来个 Notes……」算了，给他压缩一下丢目录下的 jiamu.zip 好了。
PS: 就是一台小鸡鸡，不需要使用扫描工具，也请不要泄露此题有关的任何服务器信息，谢谢！
Hints:
1. 此题需要 MeowGame 平台，地址在 Task1 最后一步，当然还可以自己找（
2. README...
———————
（久等了，喵喵出的大概就这些题目了吧，出不动了
（后面还有其他师傅出的题
（平台还没写完，过几天有空摸鱼了再慢慢写
（红包等有人解出来了再放吧，有问题可以进群反馈一下

## **jiamu.zip**

这个文件在平台www的根目录下：

[https://meowgame.2021.miaotony.xyz/jiamu.zip](https://meowgame.2021.miaotony.xyz/jiamu.zip)

下载下来是的内容是一个`.git`目录，我们将其重命名为`.git` 然后执行`git checkout .` 检出最新的内容：

其中有一个名为`NotesByJiaMu.txt` 的文件：

```
Hi, MiaoTony!

I have finished my part of work.
Just login with your private key.
Enjoy but use with care please.
Finally, happy the year of ox!

From: JiaMu
```

## **ssh**

这里需要祭出一个很好用的git技巧，叫 `git map`。关于这个命令，可以参考 [https://stackoverflow.com/a/1838938](https://stackoverflow.com/a/1838938)。其实它是一个alias，它相当于：

```bash
git log --graph --full-history --all --color \
        --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"
```

我们用 `git map` 命令来检查一下提交树。

```
* c8717dc        (HEAD -> master, origin/master, origin/HEAD) Refactor: Remove some redundant codes. (miaotony)
| *   970bf67    (refs/stash) On master: Stash some changes. (miaotony)
|/|\
| | * 43a22d2    untracked files on master: 130141d Feat: Add check flag function and UI. (miaotony)
| * 517f5b7      index on master: 130141d Feat: Add check flag function and UI. (miaotony)
|/
* 130141d        Feat: Add check flag function and UI. (miaotony)
* 04cc0bc        Feat: Add Vercel configuration. (miaotony)
* a9e4730        Feat: Add HomePage. (miaotony)
* 4bf6d24        Feat: Init Vuetify. (miaotony)
* a1993fc        Feat: Init project. (miaotony)
* dcf8a35        Initial commit (MiaoTony)
```

可以看到有一个stash节点，可以猜测上面的`git魔法功能`是stash

```
[imlk@imlk-pc jiamu]$ git show 43a22d2
commit 43a22d29c8a4352c3c7530c2036ebe59314b71f2
Author: miaotony <41962043+miaotony@users.noreply.github.com>
Date:   Mon Feb 15 03:03:21 2021 +0800

    untracked files on master: 130141d Feat: Add check flag function and UI.

diff --git a/.ssh/id_rsa b/.ssh/id_rsa
new file mode 100644
index 0000000..b444c96
--- /dev/null
+++ b/.ssh/id_rsa
@@ -0,0 +1,27 @@
+-----BEGIN OPENSSH PRIVATE KEY-----
+b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn
+NhAAAAAwEAAQAAAQEApKMZUD/pBcKpml2dx1ky0BHmA5OMOIaGq0VUp//kW5Scda4UkrsA
+3VKgAtELkTPeYIx27ZwQJZ8z2Bttav9t1E76oIaMpGHh/5mDDEeeLOFFbZKKr0bQCJHoVl
+m6EqjYvCILw5wwxVNXWort/4a+PPV5Rg8mjfcWI4giinckUrYUsoU9K6JfgPW765TYes2E
++OEMMYWDEnc7qIED5W6HNLG8X6x4Sx8820LBrVmgcyARes64WXR/J8NXViEhmni9kEisOS
+ruG+DQkdOoBURyMKFb8FC/FvRqAjkLwUb3sJoNjv+KNWeTBhF8VTYYNl9z6HL5Cd5DbuOW
+3VlKMtIyCQAAA9CKEbyOihG8jgAAAAdzc2gtcnNhAAABAQCkoxlQP+kFwqmaXZ3HWTLQEe
+YDk4w4hoarRVSn/+RblJx1rhSSuwDdUqAC0QuRM95gjHbtnBAlnzPYG21q/23UTvqghoyk
+YeH/mYMMR54s4UVtkoqvRtAIkehWWboSqNi8IgvDnDDFU1daiu3/hr489XlGDyaN9xYjiC
+KKdyRSthSyhT0rol+A9bvrlNh6zYT44QwxhYMSdzuogQPlboc0sbxfrHhLHzzbQsGtWaBz
+IBF6zrhZdH8nw1dWISGaeL2QSKw5Ku4b4NCR06gFRHIwoVvwUL8W9GoCOQvBRvewmg2O/4
+o1Z5MGEXxVNhg2X3PocvkJ3kNu45bdWUoy0jIJAAAAAwEAAQAAAQAOKS0zNtwPL8gwy96X
+V/fD59Y19on4DrIkpyj57kuxCN5QTPHeERGo98Nlmp95FNIK0eok0+ibo87sxqcpreC/gy
++RgSE1vmmW95hLBRn42EOFgjZFjzyzkAFA9CTKGBXUUMVcROH5BwsbcZm5Adj5G1AcE4+I
+ZHlWAw6dhFPufTF/I64fDsp1Mh8v5C7FVudC4eWVYz4XyYvH3z4pUVowV9o36LKrI6kfeW
+Rl61YX5lNprVpPqa9XT+4Kjx+LRuiKkWwxppACXSFATIJcLFWjR/hWsOxjY5VcJHZ6mysi
+Rehu/SoSipIGAdmdufY7uJLqfpToPDIrrcLi9kvHkxllAAAAgC+HcS8jAj36Ud5SOFWdId
+MUxdGTHssAFk4vP9B42qh3og+c5KxeCboswgW583OkfHWzKnf/J/FvwCVsIgsHk2IfGJDe
+qjBjCiTb+nzZSXh0Z5MfGNH8VbJeTz5lwcxGVy4RsVLT0I27dE7bY9BBnlB2FnW72QjP7z
+2rb/jNJC6gAAAAgQDWSOy733NQ5wHNb7cDoJ6GUsrAJN8Pqs7nPsO+kqNlliKyHkDGhbXY
+xhIIPbZBxsHq871pS1fyFbqIjONGmYD0llqA4+6Zl71g9J+7dlkfVYsp6D76fT00eU3qBQ
+HnVxz9QsZAHwvLdjTxxa/ilxHSCyxmz+P2inwpqar5fxCEVwAAAIEAxK/vMGGfkfCfTrdM
+BY7bLZ3nxZChwFXTfizWeWNYqhpbJslZaWNkkKxldMFw9Z6WlhCXsKZLdroOA6vlhScYZp
+ZiTePNTswdGHHX1uj9UPdC5npGN8G6FOT7LiFgu6HJPJTQYTdvsNQf8/x9/cb1aK9LOwob
+QK50eu32N7rwAJ8AAAAZSGFwcHlOZXdZZWFyQDgwMGJlNzg4ZTQ1YwEC
+-----END OPENSSH PRIVATE KEY-----
diff --git a/.ssh/id_rsa.pub b/.ssh/id_rsa.pub
new file mode 100644
index 0000000..7283c84
--- /dev/null
+++ b/.ssh/id_rsa.pub
@@ -0,0 +1 @@
+ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkoxlQP+kFwqmaXZ3HWTLQEeYDk4w4hoarRVSn/+RblJx1rhSSuwDdUqAC0QuRM95gjHbtnBAlnzPYG21q/23UTvqghoykYeH/mYMMR54s4UVtkoqvRtAIkehWWboSqNi8IgvDnDDFU1daiu3/hr489XlGDyaN9xYjiCKKdyRSthSyhT0rol+A9bvrlNh6zYT44QwxhYMSdzuogQPlboc0sbxfrHhLHzzbQsGtWaBzIBF6zrhZdH8nw1dWISGaeL2QSKw5Ku4b4NCR06gFRHIwoVvwUL8W9GoCOQvBRvewmg2O/4o1Z5MGEXxVNhg2X3PocvkJ3kNu45bdWUoy0jIJ HappyNewYear@800be788e45c
```

这个stash里面包含了一对ssh密钥，将它保存下来

## **hint**

README.md里面提到:

```markdown
<!--
    听说注释里可以藏东西，不如把 hint 藏这里吧
    注意看看配置文件，喵w~
-->
```

这个配置文件应该是指`vue.config.js`

用 `git log vue.config.js`查看该文件的变更：

```
commit 04cc0bc395aa87cac275c1af5711e1e1ab69623d
Author: miaotony <41962043+miaotony@users.noreply.github.com>
Date:   Fri Feb 12 04:20:08 2021 +0800

    Feat: Add Vercel configuration.

commit a9e4730b8f8bf8ffc1cc52e83743752522d3ca1f
Author: miaotony <41962043+miaotony@users.noreply.github.com>
Date:   Fri Feb 12 03:46:17 2021 +0800

    Feat: Add HomePage.

commit 4bf6d24303c6bc213b8df7a1413d2f38ba6a68ca
Author: miaotony <41962043+miaotony@users.noreply.github.com>
Date:   Thu Feb 11 21:38:32 2021 +0800

    Feat: Init Vuetify.

```

其中`04cc0bc395aa87cac275c1af5711e1e1ab69623d`比较可疑

```diff
[imlk@imlk-pc jiamu]$ git show 04cc0bc395aa87cac275c1af5711e1e1ab69623d
commit 04cc0bc395aa87cac275c1af5711e1e1ab69623d
Author: miaotony <41962043+miaotony@users.noreply.github.com>
Date:   Fri Feb 12 04:20:08 2021 +0800

    Feat: Add Vercel configuration.

diff --git a/.gitignore b/.gitignore
index b7b075a..45bc65f 100644
--- a/.gitignore
+++ b/.gitignore
@@ -117,3 +117,5 @@ dist
 node_modules
 /dist
 .vercel
+secret*
+api/
diff --git a/vercel.json b/vercel.json
new file mode 100644
index 0000000..91e16c0
--- /dev/null
+++ b/vercel.json
@@ -0,0 +1,11 @@
+{
+       "version": 2,
+       "routes": [{
+               "headers": {
+                       "Access-Control-Allow-Origin": "*"
+               },
+               "src": "/api(.*)",
+               "dest": "api/main.py",
+               "continue": true
+       }]
+}
\ No newline at end of file
diff --git a/vue.config.js b/vue.config.js
index 38c5d6e..c09d4b7 100644
--- a/vue.config.js
+++ b/vue.config.js
@@ -5,7 +5,6 @@ module.exports = {
   devServer: {
     host: '0.0.0.0',
     port: '8888',
-    // public: 'host.al0ngurl.ucan' + 'n0tf1nd.2021.miao' + 'tony.xyz' + ':8123',
   },
   lintOnSave: false,
   productionSourceMap: false
```

果然出现了一个域名，试试ssh登录上去：
根据上面的`id_rsa.pub`得知username应该是`HappyNewYear`:

```
[imlk@imlk-pc jiamu]$ ssh -i ../id_rsa  HappyNewYear@host.al0ngurl.ucann0tf1nd.2021.miaotony.xyz -p 8123
Last login: Sat Feb 27 01:45:32 2021 from 140.238.14.16
  _ __ ___   ___  _____      __
 | '_ ` _ \ / _ \/ _ \ \ /\ / /
 | | | | | |  __/ (_) \ V  V /
 |_| |_| |_|\___|\___/ \_/\_/

  Welcome to MiaoTony's box

  What are you doing?
$ cat /fl4g
miao{th1s_15_@_f4k3_$lag}
Meow~ What are you looking for?
The real flag?
I hid it! QwQ
```

看起来是个fake flag

真实的flag在这里：

```
$ cat '/.git/.s0meth1n9_s3cR37_Y0u_c@nn0t_s33/.r3@l_l0ng_And_LOn93r_$lag'
miao{M3ovv_SO_H4ppy_70_53E_u_h3Re}
Enjoy!
```

flag是 `miao{M3ovv_SO_H4ppy_70_53E_u_h3Re}`

# problem4

## 题目

> #闯关 #MeowGame
Task 4
cuso4-5h2o 给喵喵丢来一张图，说写了一个小游戏，拿到 50,000,000 分时能拿到神秘奖励，但获取奖励的选项无法选中，似乎是拼错了什么单词。
「这不就两张一样的图么？」喵喵用尾巴挠了挠脑袋，没有什么头绪，不如去睡大觉吧……
P.S.: 本题为动态 flag。感谢 @cuso45h2o 供题。
Hint:
实际分数比最大的可能得分小20亿也会判定为 cheat

题目中的图片：

![task4.png](/images/blog/69/task4.png)

## **双图**

首先切图，分别保存下来

```python
from PIL import Image

img = Image.open("task4.png")
print(img.size)
cropped1 = img.crop((0, 0, 1280, 843))  # (left, upper, right, lower)
cropped2 = img.crop((0, 843, 1280, 843*2))  # (left, upper, right, lower)
```

参考下面这里的总结：
[https://v0w.top/2018/10/22/CTF%E4%B8%AD%E5%B8%B8%E8%A7%81%E7%9A%84%E9%9A%90%E5%86%99%E6%9C%AF%E5%A5%97%E8%B7%AF/#1-8-BrainTools](https://v0w.top/2018/10/22/CTF%E4%B8%AD%E5%B8%B8%E8%A7%81%E7%9A%84%E9%9A%90%E5%86%99%E6%9C%AF%E5%A5%97%E8%B7%AF/#1-8-BrainTools)

双图隐藏数据一般是像素内容进行xor或者sub运算，或者可能是盲水印。

用ImageMagick的compare工具比较下两张图的差异点：

```bash
compare cropped1.png cropped2.png compare_no_bg.png
```

发现差异部分呈现出有规律的短条纹状，基本可以断定是盲水印

![compare_no_bg.png](/images/blog/69/compare_no_bg.png)

## **盲水印**

使用下面这个库：
[https://github.com/chishaxie/BlindWaterMark](https://github.com/chishaxie/BlindWaterMark)

注意python2和python3的随机数算法不同，解出来的东西也不一样，这里需要使用python3的。
随机数种子是`2333`

```bash
python bwmforpy3.py decode ../cropped1.png ../cropped2.png ../out.png --seed 2333
```

![out.png](/images/blog/69/out.png)

找到如下内容：

```
protamine-meowgame.cuso-4.com
username: meow 
password: 2021-01-01
```

## **网页**

这里面是一个游戏，按f12分析网络请求。这里有两个需要处理的点。

- 作者留下的代码会触发断点调试，这个可以在f12里屏蔽掉调试器
- 该网页加载了一个block-me.js，内容如下

```jsx
[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]][([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]]((!![]+[])[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+([][[]]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+!+[]]+(+[![]]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+!+[]]]+(!![]+[])[!+[]+!+[]+!+[]]+(+(!+[]+!+[]+!+[]+[+!+[]]))[(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([]+[])[([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]][([][[]]+[])[+!+[]]+(![]+[])[+!+[]]+((+[])[([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]]+[])[+!+[]+[+!+[]]]+(!![]+[])[!+[]+!+[]+!+[]]]](!+[]+!+[]+!+[]+[!+[]+!+[]])+(![]+[])[+!+[]]+(![]+[])[!+[]+!+[]])()((![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(+(+!+[]+(!+[]+[])[!+[]+!+[]+!+[]]+[+!+[]]+[+[]]+[+[]]+[+[]])+[])[+[]]+([][[]]+[])[+!+[]]+(!![]+[])[+[]]+(!![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+!+[]]+(+(!+[]+!+[]+!+[]+[+!+[]]))[(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([]+[])[([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]][([][[]]+[])[+!+[]]+(![]+[])[+!+[]]+((+[])[([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(![]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[])[+!+[]]+([][[]]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]]+[])[+!+[]+[+!+[]]]+(!![]+[])[!+[]+!+[]+!+[]]]](!+[]+!+[]+!+[]+[!+[]+!+[]])+(![]+[])[+!+[]]+(![]+[])[!+[]+!+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[+!+[]+[!+[]+!+[]+!+[]]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[+!+[]+[!+[]+!+[]+!+[]]]+([+[]]+![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[!+[]+!+[]+[+[]]]+([]+[])[(![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(!![]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(![]+[])[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]]()[+!+[]+[+!+[]]]+([]+[])[([![]]+[][[]])[+!+[]+[+[]]]+(!![]+[])[+[]]+(![]+[])[+!+[]]+(![]+[])[!+[]+!+[]]+([![]]+[][[]])[+!+[]+[+[]]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(![]+[])[!+[]+!+[]+!+[]]]()[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[!+[]+!+[]+[+[]]]+(![]+[])[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]+([![]]+[][[]])[+!+[]+[+[]]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(+(+!+[]+[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+[!+[]+!+[]]+[+[]])+[])[+!+[]]+(!![]+[])[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+(![]+[])[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(![]+[])[+!+[]]+([][[]]+[])[!+[]+!+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[+!+[]+[!+[]+!+[]+!+[]]]+([+[]]+![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[!+[]+!+[]+[+[]]]+([]+[])[(![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(!![]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(![]+[])[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]](+[![]]+([]+[])[(![]+[])[+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+(!![]+[])[+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(![]+[])[!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+(!![]+[])[+!+[]]]()[+!+[]+[!+[]+!+[]]])[!+[]+!+[]+[+!+[]]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[(![]+[])[!+[]+!+[]+!+[]]+(![]+[])[!+[]+!+[]]+([![]]+[][[]])[+!+[]+[+[]]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]]((+((+(+!+[]+[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+[!+[]+!+[]]+[+[]])+[])[+!+[]]+[+[]+[+[]]+[+[]]+[+[]]+[+[]]+[+[]]+[+!+[]]])+[])[!+[]+!+[]]+[+!+[]])+[[]][([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(!![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[+!+[]+[+[]]]+([][[]]+[])[+!+[]]+([][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]+[])[!+[]+!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]]([[]])+[]+[+!+[]]+[+[]]+[+[]]+[+[]]+[+[]]+([+[]]+![]+[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]])[!+[]+!+[]+[+[]]]);
```

是jsfuck编码，用 [https://enkhee-osiris.github.io/Decoder-JSFuck/](https://enkhee-osiris.github.io/Decoder-JSFuck/) 这个工具解密出来是：

```jsx
setInterval(()=>{location.reload();},10000)
```

这是造成网页不断刷新的原因。

可以利用chrome 的 Local Override机制替换被加载的任意文件，将这个文件替换掉，具体使用方法如下：
[https://developers.google.com/web/updates/2018/01/devtools#overrides](https://developers.google.com/web/updates/2018/01/devtools#overrides)

## **游戏**

这游戏是一个类似于flappy bird的游戏，最后得分超过`50000000`分后会发送一个请求：

```python
curl 'https://protamine-meowgame.cuso-4.com/api/report' \
  -H 'authority: protamine-meowgame.cuso-4.com' \
  -H 'pragma: no-cache' \
  -H 'cache-control: no-cache' \
  -H 'authorization: Basic bWVvdzoyMDIxLTAxLTAx' \
  -H 'sec-ch-ua: "Google Chrome";v="89", "Chromium";v="89", ";Not\"A\\Brand";v="99"' \
  -H 'dnt: 1' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.72 Mobile Safari/537.36' \
  -H 'content-type: application/json' \
  -H 'accept: */*' \
  -H 'origin: https://protamine-meowgame.cuso-4.com' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://protamine-meowgame.cuso-4.com/' \
  -H 'accept-language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,ja-JP;q=0.6,ja;q=0.5,zh-TW;q=0.4' \
  -H 'cookie: __cfduid=d07a9aa098d3456860bd08378d92a4ecc1614590625' \
  --data-raw '{"id":"aW1saw==","score":"40","picking_log":"20,20"}' \
  --compressed
```

其中得分和每步骤的得分分别由`score`和`picking_log`字段记录。

### **假的解法**

简单的思路是通过构造很长的 `picking_log`，但是出题人限制了单个请求大小的限制，过长会导致http返回413错误。

经过测试，将每次得分设置为999是最好的答案，整个请求的大小 能够符合限制。

最后report请求返回一个flag：`miao{p_c2c0580470}`

### **真的解法**

赛后查看源码：
[https://github.com/cuso4-5h2o/protamine-meowgame/blob/main/server/src/main.rs#L18](https://github.com/cuso4-5h2o/protamine-meowgame/blob/main/server/src/main.rs#L18)

`score`和`picking_log`的解析：

```rust
let score = Regex::new(r"[^0-9]")
    .unwrap()
    .replace_all(game_info.score.as_str(), "")
    .parse::<u32>()
    .unwrap();
let picking_log = Regex::new(r"[^0-9,\-]")
    .unwrap()
    .replace_all(game_info.picking_log.as_str(), "")
    .to_string();
```

可以发现`score`字段会忽略正负号，解析成`u32`类型。

接下来看验证部分：

```rust
fn verify_game(score: u32, picking_log: String) -> bool {
    let picking_log: Vec<&str> = picking_log.split(",").collect();
    let mut max_score: u32 = 0;
    for this_score_str in picking_log.iter() {
        let this_score = this_score_str.parse::<i64>().unwrap();
        if this_score > 1350 {
            return false;
        }
        max_score += this_score as u32;
    }
    return (max_score >= score) && (max_score <= (score + 2000000000));
}
```

可以发现这里有两个验证：

1. `picking_log`字段字符串的每一个值先parse成`i64`与`1350`比较判断是否单次得分过高的作弊。
2. 然后再将每一步的分数从`i64`cast成`u32`类型相加，这里`i64`转`u32`是直接截取的低32位解释成无符号数，因此负数会被解释成大于等于`2^31`的正数。

    之后和`score`比较，首先要满足`max_score >= score` ，其次还有一个`max_score <= (score + 2000000000)`的判断，我们可以在`picking_log`中使用一些特殊的分数来绕过。

经过分析代码，我们可以用`-2000000000 - 1`这个分数，构造下面这样的分数：

`"score":"2294967295", "picking_log":"-2000000001"`
下面这个curl命令可以拿到flag

```bash
curl 'https://protamine-meowgame.cuso-4.com/api/report' \
  -H 'authority: protamine-meowgame.cuso-4.com' \
  -H 'pragma: no-cache' \
  -H 'cache-control: no-cache' \
  -H 'authorization: Basic bWVvdzoyMDIxLTAxLTAx' \
  -H 'sec-ch-ua: "Google Chrome";v="89", "Chromium";v="89", ";Not\"A\\Brand";v="99"' \
  -H 'dnt: 1' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.72 Mobile Safari/537.36' \
  -H 'content-type: application/json' \
  -H 'accept: */*' \
  -H 'origin: https://protamine-meowgame.cuso-4.com' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://protamine-meowgame.cuso-4.com/' \
  -H 'accept-language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,ja-JP;q=0.6,ja;q=0.5,zh-TW;q=0.4' \
  -H 'cookie: __cfduid=d07a9aa098d3456860bd08378d92a4ecc1614590625' \
  --data-raw '{"id":"aW1saw==","score":"2294967295","picking_log":"-2000000001"}' \
  --compressed
```

flag是`miao{p_c2c0580470}`
