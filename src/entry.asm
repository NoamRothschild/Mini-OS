%ifndef STACK_SIZE
    %error "STACK SIZE SHOULD BE DEFINED"
%else
    stack_size equ STACK_SIZE
%endif

section .bss
    stack: resb stack_size
    stack_top equ stack + stack_size

section .data
    stack_len dd stack_size

section .multiboot
    ALIGNMENT equ 1 << 0
    MEMINFO equ 1 << 1
    MBOOT_MAGIC equ 0x1BADB002
    FLAGS equ ALIGNMENT | MEMINFO

    dd MBOOT_MAGIC            ; multiboot1
    dd FLAGS                  ; flags
    dd -(MBOOT_MAGIC + FLAGS) ; checksum
    dd 0                      ; padding

section .text
bits 32
global _start
global stack_len

extern kmain

_start:
    lea esp, [stack_top]
    mov ebp, esp

    call kmain
    
.keep_alive:
    nop
    jmp .keep_alive
    hlt