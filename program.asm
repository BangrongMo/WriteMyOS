NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff
VGACMDPORT equ 0x3d4
VGADATAPORT equ 0x3d5

section head align=16 vstart=0

	Size dd ProgramEnd;偏移4B 0x00,程序大小 
	SegmentAddr : ;显示各个段的地址
	CodeSeg dd section.code.start;4B 0x04  nasm 提供的点语法 section.code.start代表code段的汇编地址
	DataSeg dd section.data.start;4B 0x08  section.data.start代表data段的汇编地址
	StackSeg dd section.stack.start;4B 0x0c 
	SegmentNum:           
	SegNum db (SegmentNum-SegmentAddr)/4;1B 0x10 计算SegNum到SegmentAddr之间有多少个段，每个段占4字节,
										;计算有多少个段，以便bootloader加载到cl作为循环次数，重新计算段偏移
	
	Entry dw CodeStart; 2B 0x11  入口点地址，由段+偏移组成, CodeStart是偏移 ，
		  dd section.code.start; 4B 0x13  段地址 
	
	
section code align=16 vstart=0

CodeStart: ;初始化寄存器的各个段
	mov ax,[DataSeg]
	mov ds,ax 
	mov ax,[StackSeg]
	mov ss,ax
	mov sp ,StackEnd
	xor si,si
	call PrintLine
	jmp $
	
PrintLine:

	mov cx,HelloEnd-Hello ;类似for循环，先确定循环次数
	xor si,si
	mov bl,0x07 ;指定字符的显示属性,白色（0x7）,黑色（0x0）
	.putc:
	mov al,[si]
	inc si
	mov ah,0x0e
	int 0x10
	loop .putc

	ret

%if 0
	xor si,si;   类似while循环，每次需要判断字符是否为0x00,消耗更多cpu周期
	mov bl, 0x07
	.putc:
	mov al,[si]
	cmp al,0x00
	je .return
	inc si
	mov ah,0x0e
	int 0x10
	loop .putc
	.return:
	ret
%endif	
	
	
%if 0
PrintString:
    .setup:
    push ax
	push bx
	push cx
	push dx
	;Clear screen
	;mov ax, 3
	;int 10h
	;mov ax,0x9999
	mov ax,VIDEOMEM
	mov es,ax
	xor di,di
	
	mov bh,SETCHAR
	mov cx,STRINGLEN 
	
	.printchar:
	mov bl,[ds:si]
	
	cmp bl,0x0d
	jz .putCR
	cmp bl,0x0a
	jz .putLF
	or bl,NUL ;优化执行流程，写入显存以前应该先判断是换行还是回车还是普通字符
	jz .return
	
	
	
	inc si
	mov [es:di],bl
	inc di
	mov [es:di],bh
	inc di
	call SetCursor
	jmp .loopEnd

	;字符输出中，每输出一个字符，si+1,di+2
	;0xOD 输出回车 0x0A 换行
	 .putCR: ;计算当前行第一个字符在屏幕总字符的位置 之planA :321 / 160 =2,2x160=320.得到开头字符是第320个
	 ;mov bl,160
	 ;mov ax,di
	 ;div bl
	 ;mul bl
	 ;mov di,ax
	 
	 mov bl,160 ;planB 321/160=2...1,321-1=320,得到开头字符是第320个
	 mov ax,di
	 div bl ;低八位AL 存储除法的商,高八位 AH 存储除法的余数。
	 shr ax,8 ;让al存储余数
	 sub di, ax
	 call SetCursor
	 inc si
	 jmp .loopEnd
	 
	 
	 .putLF: ;换行
	 add di,160;
	 call SetCursor
	 inc si
	 jmp .loopEnd
 
	.loopEnd:
	loop .printchar
	.return:
	  mov bx, di
	 pop dx
	 pop cx
	 pop bx
	 pop ax
	  ret

SetCursor:
	push dx
	push bx
	push ax
	mov ax,di
	mov dx,0
	mov bx,2
	div bx ;计算字符地址，因为一个di =2*si
	
	mov bx,ax
	mov dx,VGACMDPORT
	mov al ,0x0e ;显卡寄存器 低位
	out dx,al;
	mov dx,VGADATAPORT
	mov al,bh
	out dx,al 
	mov dx,VGACMDPORT
	mov al,0x0f ;高位
	out dx,al
	mov dx,VGADATAPORT
	mov al,bl
	out dx,al
	
	
	pop ax
	pop bx
	pop dx
	ret
%endif

READSTART dd 10
SECTORNUM  db 1
DESTMEM	   dd 0x10000


section data align=16 vstart=0
	Hello db 'Hello World ,I am from program on sector 2,loaded by bootloader'
	db 0x0d , 0x0a
	db 'now system is testing new line function if cr lt do not work ,halt the OS'
	db 0x0a
	db 'this line test 0x0a'
	db 0x0d
	db 'this line test 0x0d'
	dw 0x0a0d
	db 'this line test 0x0d 0x0a'
	dw 0x0a0d
	db 'this context output powered by bios int 0x10'
	HelloEnd db 0x00
	StackEnd:
section stack align=16 vstart=0
	times 128 db 0 ;同样占位128,替代resb 128,避免警告
section end align=16
	ProgramEnd:
