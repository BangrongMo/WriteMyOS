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

文件系统中用4个字节描述一个簇，簇往往在4096b~128k之间





### End