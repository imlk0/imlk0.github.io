---
title: 用位运算来模拟数组实现一道算法题
id: 24
aliases:
  - /blog/24/
categories:
  - Algorithm
date: 2017-12-09T12:26:58+08:00
tags:
---

输入一串字符串'\n'结尾，X代表小偷，#代表普通人，数字代表警察，其数字是警察能巡视到的范围。
输出小偷个数，换行。

```
#include <stdio.h>

int printBin(unsigned long num){
	while(num != 0){
		printf("%d ", num % 2);
		num = num >> 1; 
	}
	printf("\n");
}

int main(){
	unsigned long line = 0,rangeLine = 0;
	int index = 0,range,count = 0;
	char tmp;

	scanf("%c",&tmp);
	while(tmp != '\n'){

		if(index < 20){
			if(tmp == 'X'){
				line = line | (1 << index);
			}else if(tmp == '#'){		

			}else{
				range = tmp - '0';

				for(int i = 0; i <= range; i++){

					rangeLine = rangeLine | (1 << index + i);
					rangeLine = rangeLine | (1 << index - i);
				}
			}

			// printBin(line);
			// printBin(rangeLine);

			index++;
			scanf("%c",&tmp);

		}else{
			while(index >= 10){

				if(rangeLine & 1){
					if(line & 1){
						count++;
					}
				}
				index--;
				line = line >> 1;
				rangeLine = rangeLine >> 1;
			}

		}
	}

	index--;

	while(index >= 0){

//		printf("%d %d\n",line & 1,rangeLine & 1);
		if(rangeLine & 1){
			if(line & 1){
				count++;
			}
		}
		index--;
		line = line >> 1;
		rangeLine = rangeLine >> 1;

	}

	printf("%d",count);
	return 0;
}
```
