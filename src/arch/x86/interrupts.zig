const syscall = @import("syscall.zig");
const debug = @import("../../debug.zig");
pub const HandlerType = fn (*const cpuState) callconv(.C) void;
pub var handlers_map: [0xff]*const HandlerType = undefined;

pub const cpuState = packed struct {
    gs: u16,
    fs: u16,
    es: u16,
    ds: u16,

    edi: u32,
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,

    interrupt_id: u32,
    error_code: u32, // if 0 no err code

    eip: u32,
    cs: u32,
    eflags: u32,
};

pub fn init() void {
    // set default handlers
    for (&handlers_map) |*entry|
        entry.* = dump;
}

pub fn setHandler(id: u32, handler: HandlerType) void {
    handlers_map[@as(usize, id)] = handler;
}

pub fn createIsrTrap(id: comptime_int) fn () callconv(.naked) noreturn {
    return struct {
        pub fn foo() callconv(.naked) noreturn {
            asm volatile ("cli");

            if ((id == syscall.id) or ((id != 8) and !((id >= 10) and (id <= 14)) and (id != 17))) {
                asm volatile ("pushl $0");
            }

            asm volatile (
                \\ pushl %[id]
                \\ jmp %[isrTrap:P]
                :
                : [id] "i" (@as(u32, @truncate(id))),
                  [isrTrap] "X" (&isrTrap),
            );
        }
    }.foo;
}

fn isrTrap() callconv(.naked) noreturn {
    asm volatile (
        \\ pusha
        \\ mov %ds, %ax
        \\ push %ax
        \\ mov %es, %ax
        \\ push %ax
        \\ mov %fs, %ax
        \\ push %ax
        \\ mov %gs, %ax
        \\ push %ax
    );

    asm volatile (
        \\ push %esp
        \\
        \\ mov 0x2c(%esp), %eax // offset of interrupt_id on stack
        \\ and $0xff, %eax
        \\ shl $2, %eax
        \\ mov (%ebx,%eax), %ebx
        \\ call *%ebx
        \\
        \\ add $4, %esp
        :
        : [handlers_map] "{ebx}" (&handlers_map),
        : "eax", "ebx", "memory"
    );

    asm volatile (
        \\ pop %ax
        \\ mov %ax, %gs
        \\ pop %ax
        \\ mov %ax, %fs
        \\ pop %ax
        \\ mov %ax, %es
        \\ pop %ax
        \\ mov %ax, %ds
        \\ popa
        \\ add $8, %esp
        \\ sti
        \\ iret
    );
}

fn dump(cpu_state: *const cpuState) callconv(.C) void {
    const err_msg = switch (cpu_state.interrupt_id) {
        0 => "Division by zero",
        1 => "Debug",
        2 => "Non maskable interrupt",
        3 => "Breakpoint",
        4 => "Overflow",
        5 => "Bound range exceeded",
        6 => "Invalid opcode",
        7 => "Device not available",
        8 => "Double fault",
        9 => "Coprocessor segment overrun",
        10 => "Invalid TSS",
        11 => "Segment not present",
        12 => "Stack segment fault",
        13 => "General protection fault",
        14 => "Page fault",
        15 => "Reserved",
        16 => "x87 floating point exception",
        17 => "Alignment check",
        18 => "Machine check",
        19 => "SIMD floating point exception",
        20 => "Virtualization exception",
        21 => "Control protection exception",
        22...31 => "Reserved",
        syscall.id => "Syscall",
        else => "Unknown trap gate caught",
    };
    debug.printf(
        "{s}interrupt {d} caught: {s}\nCPU state:\n{any}\n\n",
        .{
            (if (cpu_state.interrupt_id <= 31) "Hardware " else ""),
            cpu_state.interrupt_id,
            err_msg,
            cpu_state.*,
        },
    );

    if (cpu_state.interrupt_id != syscall.id)
        asm volatile ("hlt");
}
