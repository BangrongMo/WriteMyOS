[TOCM]

[TOC]

# FAT32:
### 1、mbr bootloader加载分区表，从每个分区描述的开头查找活动分区
### 2、文件系统中用4个字节描述一个簇，簇往往在4096b~128k之间
### 3、从分区表找到活动的分区
mbr分区表lbe地址（一行16字节）:
第一个000001be  80 00 15 00 0c 03 e0 ff  14 00 00 00 ec e7 0e 00                                                起始LBA在 offset 8–11，即这部分：14 00 00 00
第二个000001ce  
第三个000001de  
第四个000001ee  ，哪个地址后面跟上 0x80即表示为活动分区
### 4、进入活动分区，读取第一个扇区前90个字节，用于计算数据区位置
FAT32 参数解析

从起始 LBA 处读取第一个扇区，这是 FAT32 的 Boot Sector，里面有很多关键参数：

| 参数名称            | 偏移位置  | 描述                         |
|---------------------|-----------|------------------------------|
| BytesPerSector      | 0x0B      | 每扇区字节数（通常 512）     |
| SectorsPerCluster   | 0x0D      | 每 Cluster 包含的扇区数      |
| ReservedSectorCount | 0x0E      | Boot + FAT 前的保留扇区数    |
| NumFATs             | 0x10      | FAT 表数量（通常是 2）       |
| FATSize             | 0x24      | 每个 FAT 表所占扇区数        |
| RootCluster         | 0x2C      | 根目录起始 cluster 编号      |

### 注意：如果位置偏移不连续，代表要读多个字节 比如0x0B下一行是0x0D，代表 BytesPerSector要读0x0B  0x0C
### 由于是小端设计，先读到的是低位
### 计算数据区起始 LBA
```
DataRegionLBA = Partition_Start_LBA
              + ReservedSectorCount
              + (NumFATs × FATSize)

```

文件系统中用4个字节描述一个簇，簇往往在4096b~128k之间 ，本系统中统一使用4k一簇

# FAT数据区:
### 数据区开始就是文件系统根目录，每个文件，8字节作为文件名，3个字节作为扩展名，4字节作为大小。
### 32字节功能如下

| 字节偏移 | 大小（字节） | 含义 |
|----------|---------------|------|
| `0x00`   | 11            | 文件名（8字节）+ 扩展名（3字节），符合8.3格式 |
| `0x0B`   | 1             | 属性（如只读、系统文件、目录等） |
| `0x0C`   | 1             | 保留（通常为0） |
| `0x0D`   | 1             | 创建时间（毫秒） |
| `0x0E`   | 2             | 创建时间（小时+分钟+秒） |
| `0x10`   | 2             | 创建日期 |
| `0x12`   | 2             | 最后访问日期 |
| `0x14`   | 2             | 高 16 位起始 cluster（FAT32独有） |
| `0x16`   | 2             | 最后修改时间 |
| `0x18`   | 2             | 最后修改日期 |
| `0x1A`   | 2             | 低 16 位起始 cluster |
| `0x1C`   | 4             | 文件大小（单位：字节） |



# 实模式到保护模式到长模式
### 定义GDT 全局描述符
- 包含段描述符（*空描述符、*数据段描述符、*代码段描述符、调用门，任务门） *为必须
- LDT
- 调用门
- 任务门等
### 定义GDT后告知CPU
- GDT:
	dw GDTSize (16bit)
	dd GDTBase (32bit内存地址)
	描述一个GDT要48bit
- LGDT:
	LGDT Address ;从指定地址读取6个字节（48bit），得到的数据保存到GDTR

-	修改CPU CR0的PE位,清空流水线:

```nasm
EnableProtectModel:
	mov eax,0x40000023
	mov cr0,eax
	jmp CodeDes:ProtectLand
	BITS 32
	ProtectLand:
		mov  eax, 0x0000000A
	
```