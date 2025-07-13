[org 0x9000]
section initial align=16 vstart=0x9000

mov si,InitialLandHere
call PrintString
jmp InitialEnd



PrintString:
    push ax
    push cx
    push si
    mov cx,512
    .printchar:
    mov al,[si]
    mov ah,0x0e
    int 0x10
    cmp byte[si],0
    je .return
    inc si
    loop .printchar
    .return:
        pop si
        pop cx
        pop ax
        ret
InitialEnd:
        hlt

InitialLandHere db 'I come from  INITIAL.BIN',0x0d,0x0a,0