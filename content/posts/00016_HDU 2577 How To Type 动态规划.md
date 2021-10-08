---
title: HDU 2577 How To Type 动态规划
id: 16
categories:
  - 算法
date: 2018-02-01 17:59:56
tags:
---

> How to Type
> 
>   Time Limit: 2000/1000 MS (Java/Others)    Memory Limit: 32768/32768 K (Java/Others)
> 
>   Total Submission(s): 7448    Accepted Submission(s): 3374
> 
> 
>   Problem Description
> 
>   Pirates have finished developing the typing software. He called Cathy to test his typing software. She is good at thinking. After testing for several days, she finds that if she types a string by some ways, she will type the key at least. But she has a bad habit that if the caps lock is on, she must turn off it, after she finishes typing. Now she wants to know the smallest times of typing the key to finish typing a string.
> 
> 
>   Input
> 
>   The first line is an integer t (t&lt;=100), which is the number of test case in the input file. For each test case, there is only one string which consists of lowercase letter and upper case letter. The length of the string is at most 100.
> 
> 
>   Output
> 
>   For each test case, you must output the smallest times of typing the key to finish typing this string.
> 
> 
>   Sample Input
> 
> 
>   3
> 
>   Pirates
> 
>   HDUacm
> 
>   HDUACM
> 
> 
>   Sample Output
> 
> 
>   8
> 
>   8
> 
>   8
> 
> 
>   Hint
> 
> 
>   The string “Pirates”, can type this way, Shift, p, i, r, a, t, e, s, the answer is 8.
> 
>   The string “HDUacm”, can type this way, Caps lock, h, d, u, Caps lock, a, c, m, the answer is 8
> 
>   The string "HDUACM", can type this way Caps lock h, d, u, a, c, m, Caps lock, the answer is 8
> 
> 
>   Author
> 
>   Dellenge
> 
> 
>   Source
> 
>   HDU 2009-5 Programming Contest
> 
> 
>   Recommend
> 
>   lcy

**输入每个字符前的状态是：**
**大小写锁开启on或者关闭off**

**_注意开启锁时按shift可以输入小写_**

```cpp
#include <iostream>
#include <cstdio>

int isup(char a) {
    return (a &gt;= 'A' &amp;&amp; a &lt;= 'Z');
}
int main(int argc, char const *argv[])
{
    int t;
    char data[105];
    int off[105];
    int on[105];
    scanf("%d", &amp;t);

    while (t--) {
        int capsLock = 0;
        int ans = 0;
        scanf("%s", data);
        int i;
        // 每次输入之前锁有两种状态
        off[0] = 0;//表示输入第i个字符前状态为off/on的按键最少次数
        on[0] = 1;
        for (i = 0; data[i] != '\0'; i++) {
            if (isup(data[i])) {
                // 输入大写字母以后锁：on
                // 直接输入，按下caps再输入（原先锁off）
                on[i + 1] = min(on[i] + 1, off[i] + 2);
                // 输入大写字母以后锁：off
                // 按下caps再输入（原先锁on）,按shift输入
                off[i + 1] = min(on[i] + 2, off[i] + 2);
            } else {

                on[i + 1] = min(on[i] + 2, off[i] + 2);
                off[i + 1] = min(on[i] + 2, off[i] + 1);

            }
        }

        printf("%d\n", min(on[i] + 1, off[i]));
    }
    return 0;
}

```