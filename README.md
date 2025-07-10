# 手写操作系统
### 基于郑钢老师的 <<操作系统真象还原>> 设计的操作系统，结合个人理解，添加注释代码

### 创建bochsrc指向的硬盘: bximage -q -hd=10M -func=create  -imgmode=flat hd.img
### 编译代码:nasm -f bin bootloader.asm -o bootloader.bin -l bootloader.lst && nasm -f bin program.asm  -o program.bin -l program.lst
### 写入二进制到虚拟硬盘: dd if=bootloader.bin of=hd.img bs=512 count=1 conv=notrunc && dd if=program.bin of=hd.img seek=1 bs=512 count=1 conv=notrunc
### 通过bochs启动系统: bochs -f bochsrc
### 通过qemu启动系统:qemu-system-i386 -hda hd.img
