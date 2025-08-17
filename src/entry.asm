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
%define MBOOT2
%ifdef MBOOT1
    ALIGNMENT equ 1 << 0
    MEMINFO equ 1 << 1
    MBOOT_MAGIC equ 0x1BADB002
    FLAGS equ ALIGNMENT | MEMINFO

    dd MBOOT_MAGIC            ; multiboot1
    dd FLAGS                  ; flags
    dd -(MBOOT_MAGIC + FLAGS) ; checksum
    dd 0                      ; padding
%elifdef MBOOT2
    multiboot_start:
        MBOOT_MAGIC equ 0xe85250d6
        MBOOT_LENGTH equ multiboot_end - multiboot_start

        dd MBOOT_MAGIC ; multiboot2
        dd 0 ; protected mode i386
        dd MBOOT_LENGTH ; header length
        dd 0x100000000 - (MBOOT_MAGIC + 0 + (MBOOT_LENGTH)) ; checksum

        ; end tag
        dd 0
        dd 8
    multiboot_end:
%else
    %error "EITHER MBOOT1 OR MBOOT2 MUST BE SELECTED, ALSO UPDATE grub.cfg ACORDINGLY"
%endif

section .text
bits 32
global _start
global stack_len
global stack_top

extern kmain

_start:
    lea esp, [stack_top]
    mov ebp, esp

    call kmain
    
.keep_alive:
    nop
    jmp .keep_alive
    hlt