//
// Created by admin_mbr on 7/19/25.
//
#include <stdio.h>
#include <string.h>

int add(int x,int y);
int main(int argc, char* argv[])
{
    /*int a=0;int b =0; int result=0;char test;
    printf("%llx \n",&test);
    printf("input the math: \n");
    scanf("%d %c %d",&a,&test,&b);
    printf("value of test is %d \n",test);
    printf("a is %d,b is %d \n",a,b);
    switch (test)
    {
    case '+':result =a + b;break;
    case '-':result =a - b;break;
    default: break;

    }
    printf("result is %d \n",result);
    for (int i = 0; i < argc; ++i)
    {
       printf("argv[%d] is:",i);
        for (int j =0;j<strlen(argv[i]);j++)
        {
            printf("%c",*argv[i]);
        }
       printf("\n");
    }
    // printf("argc is %d,argv[0] is %s",argc,*argv);
    */
   /* char a = 'a';
    char* beforech=&a;
    printf("a addr is %llx \n",&beforech);
    char  chs [10] ={};
    char x ='x';
    char* px =&x;
    printf("x addr is %llx \n",px);
    printf("px addr is %llx \n",&px);
    printf("chs addr is %llx \n",chs);
    for (int i = 0; i < sizeof(chs); ++i)
    {
        chs[i]=x;
        printf("chs[%d] addr is %llx \n",i,&chs[i]);
    }
    char b ='b';
    char* after =&b;
    printf("b addr is %llx \n",&after); */
    int result =add(1,2);
    printf("result is %d",result);
    return 0;
}

int add(int x,int y)
{
    return x +y;
}
