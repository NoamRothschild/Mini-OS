bits 32
section .text

global vgaEntry
vgaEntry:
    mov al, [esp + 4]
    mov ah, [esp + 8]
    ret