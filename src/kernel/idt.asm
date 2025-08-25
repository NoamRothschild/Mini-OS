section .text

; defined in idt.zig
extern idt_trap_handler

%macro DEFAULT_TRAP 0
  mov eax, eax
  call idt_trap_wrap
  iret
%endmacro

isr_entry_len equ (trap1 - trap0)
isr_map_start equ trap0
%if isr_entry_len != 8
  %error "isr_entry_len must be 8 bytes long! (ie: 3 instructions)"
%endif

idt_trap_wrap:
  push ebp
  mov ebp, esp
  pushad
  cld

  ; [ebp + 16] EFLAGS
  ; [ebp + 12] CS
  ; [ebp + 8 ] EIP
  ; [ebp + 4 ] EIP OF TRAP

  ; calculating the int that happened based on offset in map
  ; xor edx, edx
  mov eax, [ebp + 4]
  sub eax, isr_map_start ; eax offset in map
  ; mov ebx, isr_entry_len
  ; div ebx
  shr eax, 3 ; log2(isr_entry_len) = 3, getting the actual numeric index

  push eax
  call idt_trap_handler

  popad
  mov esp, ebp
  pop ebp
  ret

global idt_entryFuncByIndex
idt_entryFuncByIndex: ; args -> (index: u32), ret -> (addr)
  push ebp
  mov ebp, esp
  push ebx

  mov eax, trap0
  mov ebx, [ebp + 8]

  ; bounds checking
  cmp ebx, 31
  ja .end
  cmp ebx, 0
  jl .end

  lea eax, [isr_map_start + isr_entry_len * ebx]

.end:
  pop ebx
  pop ebp
  ret

trap0: DEFAULT_TRAP
trap1: DEFAULT_TRAP
trap2: DEFAULT_TRAP
trap3: DEFAULT_TRAP
trap4: DEFAULT_TRAP
trap5: DEFAULT_TRAP
trap6: DEFAULT_TRAP
trap7: DEFAULT_TRAP
trap8: DEFAULT_TRAP
trap9: DEFAULT_TRAP
trap10: DEFAULT_TRAP
trap11: DEFAULT_TRAP
trap12: DEFAULT_TRAP
trap13: DEFAULT_TRAP
trap14: DEFAULT_TRAP
trap15: DEFAULT_TRAP
trap16: DEFAULT_TRAP
trap17: DEFAULT_TRAP
trap18: DEFAULT_TRAP
trap19: DEFAULT_TRAP
trap20: DEFAULT_TRAP
trap21: DEFAULT_TRAP
trap22: DEFAULT_TRAP
trap23: DEFAULT_TRAP
trap24: DEFAULT_TRAP
trap25: DEFAULT_TRAP
trap26: DEFAULT_TRAP
trap27: DEFAULT_TRAP
trap28: DEFAULT_TRAP
trap29: DEFAULT_TRAP
trap30: DEFAULT_TRAP
trap31: DEFAULT_TRAP
