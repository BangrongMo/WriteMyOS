[org 0x7c00]
section Initial align=16 vstart=0x7c00
CleanScreen:
mov ax, 3	;Clear screen
int 10h

InitRegToZero:
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov ss,ax
InitSP:
	mov sp,0x7c00 ;初始化栈
Start:
	mov si,BootloaderStart ;分区表存储在BootLoaderStart?
	call PrintString


CheckInt13:
	mov ah ,0x41 ;0x41检查int 0x13h是否可用 ,0x42是使用int 0x13读取功能
	mov bx,0x55aa ;固定值
	mov dl,0x80 ;0x80代表主盘(0x13中断加持下选择哪个启动，哪个就是)
	int 0x13
	cmp bx,0xaa55 ;判断调用结果，如果不是aa55,表明不支持
	mov byte [MyException+0x06],0x31 ;修改错误编号
	jnz BootloaderEnd

SeekTheActivePartition:
	mov di,0x7dbe ;分区表起始位置(内存中,随着mbr一起被加载进来的)
	mov cx,4
	.seekActive:
		mov bl,[di]
		cmp bl, 0x80
		je  ActiveFound
		add di,16
		loop .seekActive
		.activeNotFound:
			mov byte [MyException+0x06],0x32
			jmp BootloaderEnd

ActiveFound:
	mov si,PartitionFound
	call PrintString
	mov ebx, [di+8] ;移动到LBA地址开始处
	mov dword [BlockLow],ebx ;LBA地址是32bit
	mov word [BufferOffset],0x7e00 ;bootloader 从0x7c00~7dff,所以下一个可用地址0x7e00 （0x7e00~0x9fbff 有607kb的空间可用，详情见8086内存分布图）
	mov byte [BlockCount],1
	call ReadDisk
GetFirstFat32:
	mov di,0x7e00
	xor ebx ,ebx
	mov bx ,[di+0x0e] ;查已经使用块数
	mov eax,[di+0x1c] ;查保留块数
	add ebx,eax ;得到fat1的起始块
GetDataAreaBase:
	mov eax,[di+0x24] ;每个 FAT 表所占扇区数
	xor cx,cx
	mov cl,[di+0x10] ;FAT 表数量（通常是 2）
	.addFatSize:
		add ebx,eax ;数据区起始块,有n张表就要加n次 
		loop .addFatSize

ReadRootDir:
	mov [BlockLow],ebx
	mov word [BufferOffset],0x8000;0x7e00开始，又存储了一个fat分区的第一个扇区(大小0x200)，所以下一个地址0x8000开始
	mov di,0x8000 
	mov byte [BlockCount],8 ;准备参数读八个块，4k,一个扇区0x200空间，8个扇区 0x1000空间，下一个地址 0x9000开始
							;如果文件多，可以读更多扇区，避免找不到，当然占用内存空间也要重新计算
	call ReadDisk
	mov byte [MyException+0x06],0x34
SeekTheInitialBin:
	cmp dword [di],'INIT'
	jne .nextFile
	cmp dword [di+4],'IAL '
	jne .nextFile
	cmp dword [di+8],'BIN '
	jne .nextFile
	jmp InitialBinFound
	.nextFile:
		cmp di,0x9000
		ja BootloaderEnd
		add di,32 ;切换到下一个文件元数据
		jmp SeekTheActivePartition

InitialBinFound:
	mov si,InitialFound
	call PrintString
	mov ax,[di+0x1c] ;取文件长度地位
	mov dx ,[di+0x1e] ;取高位
	mov cx ,512 
	div cx ;算有多少个扇区,ax是商，余数dx里，一旦有余数，ax+1
	cmp dx,0
	je NoRemaider ;如果没有余数，跳过ax+1
	inc ax
	mov [BlockCount],ax
NoRemaider:
	mov ax,[di+0x1a] ;低 16 位起始簇(cluster)
	sub ax,2 ;簇号要-2
	mov cx,8 
	mul cx  ;一个簇8个扇区，所以算出具体偏移扇区

	and eax,0x0000ffff ;只要取低16位，不要前面算除法的高16位因影响ebx
	add ebx,eax ;ebx已经存储 fat1的起始扇区号，起始+偏移得到INITIAL.BIN的开始地址（物理扇区LBA）
	mov ax,dx
	shl eax,16
	add ebx,eax
	mov [BlockLow],ebx
	mov word [BufferOffset] ,0x9000;准备把INITIAL.BIN读取到0x9000以后的地址空间
	mov di,0x9000
	call ReadDisk
	mov si,GotoInitial
	call PrintString
	jmp di



;加载完program.bin后，里面编译好的段地址和偏移地址是不能直接用的，
;因为编译器是按照program作为第一个扇区的程序来设置地址的
;而bootloader实际上才是第一个扇区的，所以要重新计算program的段地址和偏移地址，
;并修改加载到内存的program，才能跳转到program执行
;mov ax, [1000h] 默认等价于 mov ax, [ds:1000h]
;jmp 1234h 那么跳转目标是 CS:1234h，在当前代码段中跳转。

%if 0
ResetSegment: ;？修改段地址到0x1000,即第二个扇区读入到内存的地址
	mov bx,0x04 ;将program段地址所在的内存地址写入bx,地址来源于program.asm中CodeSeg dd section.code.start
	mov cl,[0x10] ;0x10地址存储了program有多少个段,方便后面作为循环次数 ds本来以及指向DESTMEM，所以直接取
	
	.reset:	
	
	mov ax,[bx] ;取出段地址（其实是相对地址，[bx]存储的值是编译program.asm产生的，
				;是独立的,之后和bootloader整合就要重新计算段和偏移）
	mov dx,[bx+2]  ;由于地址是四个字节，取两次
	
	
	;汇编代码中，从内存取数据的时候，是ds:偏移地址取值，段内代码跳转的时候是cs:偏移地址 。
	;为了获得正确的段内偏移地址
	;读programer程序的大小，因为是32位，读两次
	;现在dx:ax是program初始CodeSeg地址，下面将重新计算
	
	
	
	;DESTMEM编译到了当前代码段（我需要从当前代码段（CS）中，偏移为 DESTMEM 的位置读取值）
	;,DESTMEM的值要通过cs查找，告诉cpu
	add ax,[cs:DESTMEM]  ; cs:0xffff,内存值0x0000，前面取出了ax，将两者相加
	adc dx,[cs:DESTMEM+2] ;内存值0x0001
	mov si,16 ;0x0001_0020  >> 16  =  0x1002
	div si
	mov [bx],ax ;新的地址计算完成,重写到[0x04]处
	
	
	
	add bx,4 ;准备计算下一个
	loop .reset
	
	ResetEntry:
	mov ax,[0x13] ;ax，所以取了13、14
	mov dx,[0x15] 

	
	add ax,[cs:DESTMEM] ; 
	add dx,[cs:DESTMEM+2] ;
	mov si,16
	div si  	;shr ax,4
	
	mov [0x13],ax
	
	jmp far [0x11] ;jmp far [address] 是通过该内存地址处的 4 字节（16位 offset + 16位 segment）作为目标。
					;DESTMEM:0x11是入口地址
%endif
PrintString:
	push ax
	push cx
	push si
	mov cx,512
	.printchar:
		mov al,[si]
		mov ah,0x0e
		int 0x10
		cmp byte [si],0
		je .return
		inc si
		loop .printchar	
		.return:
			pop si
			pop cx 
			pop ax
			ret

ReadDisk:
	mov ah,0x42 ;调用读取磁盘功能
	mov dl, 0x80 ;选择第一个硬盘

	mov si, DiskAddressPacket ;读取磁盘对象
	int 0x13
	test ah,ah
	mov byte [MyException+0x06],0x33;修改错误编号
	jnz BootloaderEnd
	ret

BootloaderEnd:
	mov si,MyException
	call PrintString
	hlt




DiskAddressPacket:
	PackSize db 0x10 ;整个结构体大小
	Reserved db 0
	BlockCount dw 0 ;要读取的扇区数量
	BufferOffset dw 0 ;目标内存地址。是指读进来的INITIAL.BIN在内存中的开始地址
	BufferSegment dw 0
	BlockLow	dd 0 ;磁盘起始块低地址
	BlockHigh dd 0 ;磁盘起始块高地址


MyException db "error",0x0d,0x0a,0
BootloaderStart db 'check INT 13',0x0d,0x0a,0
GotoInitial db 'READY TO BOOT',0x0d,0x0a,0
PartitionFound db 'PartitionFound',0x0d,0x0a,0
InitialFound db 'INITIAL.BIN FOUND!',0x0d,0x0a,0

End: jmp End


times 510-($-$$) db 0 ; 填充剩余空间
dw 0xAA55
