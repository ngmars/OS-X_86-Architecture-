global start
section .text
bits 32
start:
    ;to print 'OK'
    ;0xb80000 <- video memory address
    mov dword [0xb8000], 0x2f4b2f4f
    hlt