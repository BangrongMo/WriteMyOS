NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff

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

CodeStart:
	mov ax,[DataSeg]
	mov ds,ax
	xor si,si
	call PrintString
	jmp $

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
	inc si
	mov [es:di],bl
	inc di
	mov [es:di],bh
	inc di
	or bl,NUL
	jz .return
	loop .printchar
	.return:
	  mov bx, di
	 pop dx
	 pop cx
	 pop bx
	 pop ax
	  ret

READSTART dd 10
SECTORNUM  db 1
DESTMEM	   dd 0x10000


section data align=16 vstart=0
	Hello db 'Hello World ,I am from program on sector 2,loaded by bootloader',0
	
section stack align=16 vstart=0
	resb 128
section end align=16
	ProgramEnd:
