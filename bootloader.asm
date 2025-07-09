HDDPORT equ 0x1f0
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xff
NUL equ 0x00

section code align=16 vstart=0x7c00
mov ax, 3
int 10h

mov si, msg
xor di,di
call PrintString

mov si,[READSTART]
mov cx,[READSTART+0X02] ;存储lba28地址,需要四个字节,高位cx低位si
mov al,[SECTORNUM];要读入的扇区数量
push ax ;保存扇区值al,push 要用ax，所以一起ah保存了

mov ax,[DESTMEM]
mov dx,[DESTMEM+0X02]
mov bx,16 ;因为DESTMEM是完整地址，除以16计算DESTMEM的段地址
div bx

mov ds,ax ;配置段地址
xor di,di ;偏移地址置0
pop ax



call READHDD


;加载完program.bin后，里面编译好的段地址和偏移地址是不能直接用的，
;因为编译器是按照program作为第一个扇区的程序来设置地址的
;而bootloader实际上才是第一个扇区的，所以要重新计算program的段地址和偏移地址，
;并修改加载到内存的program，才能跳转到program执行
;mov ax, [1000h] 默认等价于 mov ax, [ds:1000h]
;jmp 1234h 那么跳转目标是 CS:1234h，在当前代码段中跳转。


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
	
READHDD:
	push ax
	push bx
	push cx
	push dx
	mov dx,HDDPORT+2
	out dx,al ;al存储的扇区数,写到dx端口
	
	mov dx,HDDPORT+3 ;开始写地址
	mov ax,si ;lba28低位si写到ax
	out dx,al ;写低位 0-7

	mov dx,HDDPORT+4
	mov al,ah
	out dx,al ;写高位 8-15
	
	mov dx,HDDPORT+5
	mov ax,cx ;换一个寄存器赋值到ax,写低位 16-23
	out dx,al
	
	mov dx,HDDPORT+6
	mov al,ah
	mov ah,0xe0 ;采用lba模式读取
	or al,ah
	out dx,al ;写24-27位
	
	mov dx,HDDPORT+7
	mov al,0x20 ;0x20为读模式,0x30为写模式
	out dx,al
	
	.waits: ;自旋锁循环等待磁盘io可用
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .waits
	
	mov dx, HDDPORT ;地址写完,dx挪作hddport使用
	mov cx,256 ;每次可以读2字节，所以循环256读取一个扇区
	
	.readword:
	in ax,dx ;读取端口数据到ax
	mov [ds:di],ax ;存到内存
	add di,2
	;or ah,0x00 ;因为数据以0x00结尾，所以看到0x00就退出
	;jnz .readword
	loop .readword
	.return:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PrintString:
	.setup:
	mov ax,VIDEOMEM
	mov es,ax
	mov bh,SETCHAR
	mov cx,STRINGLEN 
	
	.printchar:
	mov bl,[ds:si]
	inc si
	mov [es:di],bl
	inc di
	mov [es:di],bh
	inc di
	or bl,NUL
	jz .return
	loop .printchar
	.return:
	ret
	

READSTART  dd 1
SECTORNUM  db 1
DESTMEM	   dd 0x10000

End: jmp End
msg db 'mbr load secucess,loading next sector... ',0
times 510-($-$$) db 0 ; 填充剩余空间
dw 0xAA55
