section .text

; ------ Trap Handlers & Setup ------

; defined in Interrupts.zig
extern interrupt_trap_handler
extern irqHandler

%macro DEFAULT_TRAP 1
  %if (%1 != 8) & !( (%1 >= 10) & (%1 <= 14) ) & (%1 != 17)
    push dword 0 ; make the stack consistent across Interrupts
  %else
    nop
    nop ; keeping the size consistent across all cases
  %endif
  push dword %1
  jmp near idt_trap_stub
%endmacro

%macro IRQ_GATE 1
  push dword 0  ; push err code of 0 to align with same cpuState struct
  push dword %1 ; push irq gate number as interrupt number
  jmp irq_gate_stub
%endmacro

isr_trap_entry_len equ (trap1 - trap0)
isr_trap_map_start equ trap0

irq_gate_entry_len equ (irq2 - irq1)
irq_gate_map_start equ irq1

; pushed by cpu: {
;   EFLAGS
;   CS
;   OLD EIP
; },
; pushed by macro: {
;   ERROR
;   TRAP INDEX
; }
; pushed by handler: {
;   registers
;   flags
; }
idt_trap_stub:
  pusha

  xor eax, eax
  mov ax, ds
  push ax
  mov ax, es
  push ax
  mov ax, fs
  push ax
  mov ax, gs
  push ax

  push esp
  call interrupt_trap_handler
  add esp, 4

  xor eax, eax
  pop ax
  mov gs, ax
  pop ax
  mov fs, ax
  pop ax
  mov es, ax
  pop ax
  mov ds, ax

  popa
  add esp, 8 ; remove error code && trap index
  iret

global idt_entryFuncByIndex
idt_entryFuncByIndex: ; args -> (index: u32), ret -> (addr)
  push ebp
  mov ebp, esp
  push ebx
  push edx

  mov eax, [ebp + 8]

  ; bounds checking
  cmp eax, 31
  ja .end
  cmp eax, 0
  jl .end

  mov ebx, isr_trap_entry_len
  imul ebx
  add eax, isr_trap_map_start
  
  jmp .end
.fail:
  mov eax, trap0
.end:
  pop edx
  pop ebx
  pop ebp
  ret

global idt_irqByIndex
idt_irqByIndex: ; args -> (index: u32), ret -> (addr)
  push ebp
  mov ebp, esp
  push ebx
  push edx

  mov eax, [ebp + 8]

  ; bounds checking
  cmp eax, 16
  ja .end
  cmp eax, 0
  jl .end

  mov ebx, irq_gate_entry_len
  imul ebx
  add eax, irq_gate_map_start
  
  jmp .end
.fail:
  mov eax, irq1
.end:
  pop edx
  pop ebx
  pop ebp
  ret

trap0: DEFAULT_TRAP 0
trap1: DEFAULT_TRAP 1
trap2: DEFAULT_TRAP 2
trap3: DEFAULT_TRAP 3
trap4: DEFAULT_TRAP 4
trap5: DEFAULT_TRAP 5
trap6: DEFAULT_TRAP 6
trap7: DEFAULT_TRAP 7
trap8: DEFAULT_TRAP 8
trap9: DEFAULT_TRAP 9
trap10: DEFAULT_TRAP 10
trap11: DEFAULT_TRAP 11
trap12: DEFAULT_TRAP 12
trap13: DEFAULT_TRAP 13
trap14: DEFAULT_TRAP 14
trap15: DEFAULT_TRAP 15
trap16: DEFAULT_TRAP 16
trap17: DEFAULT_TRAP 17
trap18: DEFAULT_TRAP 18
trap19: DEFAULT_TRAP 19
trap20: DEFAULT_TRAP 20
trap21: DEFAULT_TRAP 21
trap22: DEFAULT_TRAP 22
trap23: DEFAULT_TRAP 23
trap24: DEFAULT_TRAP 24
trap25: DEFAULT_TRAP 25
trap26: DEFAULT_TRAP 26
trap27: DEFAULT_TRAP 27
trap28: DEFAULT_TRAP 28
trap29: DEFAULT_TRAP 29
trap30: DEFAULT_TRAP 30
trap31: DEFAULT_TRAP 31
; hardware gates (IRQ => interrupt requests)
irq1: IRQ_GATE 32
irq2: IRQ_GATE 33
irq3: IRQ_GATE 34
irq4: IRQ_GATE 35
irq5: IRQ_GATE 36
irq6: IRQ_GATE 37
irq7: IRQ_GATE 38
irq8: IRQ_GATE 39
irq9: IRQ_GATE 40
irq10: IRQ_GATE 41
irq11: IRQ_GATE 42
irq12: IRQ_GATE 43
irq13: IRQ_GATE 44
irq14: IRQ_GATE 45
irq15: IRQ_GATE 46
irq16: IRQ_GATE 47

; if this check does not pass, trap indexing will be off and wrong interrupts will be called
%if (trap1 - trap0) != (trap9 - trap8)
  %assign regular_size (trap1 - trap0)
  %assign special_size (trap9 - trap8)
  %error "Interrupt trap handler length is not equal to a one without a passed error. idt.asm:6 - DEFAULT_TRAP macro. non-errored size=" regular_size ", errored size=" special_size
%endif

; pushed by macro: {
;   ERROR (null)
;   IRQ_NUMBER
; }
; pushed by handler: {
;   registers
;   flags
; }
irq_gate_stub:
  pusha

  xor eax, eax
  mov ax, ds
  push ax
  mov ax, es
  push ax
  mov ax, fs
  push ax
  mov ax, gs
  push ax

  push esp
  call irqHandler 
  add esp, 4

  xor eax, eax
  pop ax
  mov gs, ax
  pop ax
  mov fs, ax
  pop ax
  mov es, ax
  pop ax
  mov ds, ax

  popa
  add esp, 8 ; remove error code && trap index
  iret

; ----- syscall -----

extern syscall_number
extern syscallHandler ; the zig handler side
global syscall_handler

; pushed by cpu: {
;   EFLAGS
;   CS
;   OLD EIP
; },
; pushed by handler (ignore): {
;   ERROR       => 0
;   TRAP INDEX  => syscall_number
; }
; pushed by handler: {
;   registers
;   flags
; }
syscall_handler:
  push dword 0
  push dword [syscall_number]
  pusha

  xor eax, eax
  mov ax, ds
  push ax
  mov ax, es
  push ax
  mov ax, fs
  push ax
  mov ax, gs
  push ax

  push esp
  call syscallHandler
  add esp, 4

  xor eax, eax
  pop ax
  mov gs, ax
  pop ax
  mov fs, ax
  pop ax
  mov es, ax
  pop ax
  mov ds, ax

  popa
  add esp, 8 ; remove empty error code && syscall_number 
  iret

