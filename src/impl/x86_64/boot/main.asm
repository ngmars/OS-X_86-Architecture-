global start
section .text
bits 32
start:
    ;to print 'OK'
    ;0xb80000 <- video memory address
    mov esp, stack_top
    call check_multiboot
    call check_cpuid
    call check_long_mode

    ;single page is of 4kb of memory 
    call setup_page_tables
    call enable_paging 

    mov dword [0xb8000], 0x2f4b2f4f
    hlt

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
.no_multiboot:
    mov al,:M"
    jmp error


check_cpuid:
    pushfd ;push the flags register to the stack
    pop eax ; pop the elements in the eax register- 
    mov ecx, eax    ; make a copy of the ecx register so we can compare later
    xor eax, 1 <<21 ;using XOR operation flip the bits (only bit 21, as it is the CPU ID bit)
    push eax   ; push the original bits back out the eax register
    popfd   ; popiing into the flags register
    pushfd  ;
    pop eax ; push back the bit obtained from the XOR operation back on the eax register
    push ecx    ;transfer value in scx into the flags register to not create an error
    popfd   ; pop it
    cmp eax,ecx ; compare eax and ecx, if they are the same, cpu id is not present, else it is present
    je .no_cpuid

.no_cpuid
    mov al, "C"
    jmp error

;Checking for long mode suppor( 64bit support)
check_long_mode:
    mov eax , 0x80000000
    cpuid ; when cpu id sees eax, it generates a number higher than it
    cmp eax, 0x80000001 ; we compare eax with a value higher than 0x80000000
    jb .no_long_mode    ; if eax is not higher, we say cpu does not support long mode
    ;use extended processor info to check if long mode is available
    mov eax, 0x80000001
    cpuid ; stores value into edx
    test edx, 1<<29 ; ln bit at bit 29
    jz .no_long_mode
    ret

.no_long_mode:
    mov al, "L"
    jmp error

setup_page_tables:
    mov eax, page_table_l3
    or eax, 0b11 ; presebt writable
    mov [page_table_l4],eax

    mov eax, page_table_l2
    or eax,0b11 ;
    move [page_table_l3]

.loop:
    mov eax, 0x200000 ; 2MiB
    mul ecx
    or eax, 0b0000011 ;present, writable huge page flag
    mov [page_table_l2 + ecx *8], eax

    mov ecx,0 ; counter
    inc ecx ; increment counter
    cmp ecx, 512 ; check if reach 512
    jne .loop; if not, continue

    ret


error:
    ;print "ERR: X" where X is our error code
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mpv byte [0xb800a], al 
    hlt

section .bss
align 4096
page_table_l4:
    resb 4096
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096
stack_bottom:
    resb 4096 * 4
stack_top:

