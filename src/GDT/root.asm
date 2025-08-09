section .data
GDT_Start:
    ; in case im stuck:
    ; https://www.youtube.com/watch?v=Wh5nPn2U_1w&list=PLm3B56ql_akNcvH8vvJRYOc7TbYhRs19M&index=6
    dq 0x00000000 ; NULL descriptor

    ; 32 bit code segment descriptor
.code_descriptor:
    dw 0xFFFF ; limit start
    db 0, 0, 0 ; first 24 base bits
    db 0b10011010 ; flags
    db 0b11001111 ; flags
    db 0 ; end part of base

    ; 32 bit data segment descriptor
.data_descriptor:
    dw 0xFFFF ; limit start
    db 0, 0, 0 ; first 24 base bits
    db 0b10010010 ; flags
    db 0b11001111 ; flags
    db 0 ; end part of base
GDT_End:

GDT_Descriptor:
    dw GDT_End - GDT_Start - 1 ; size
    dd GDT_Start               ; start

CODE_SEG equ GDT_Start.code_descriptor - GDT_Start
DATA_SEG equ GDT_Start.data_descriptor - GDT_Start