const debug = @import("../debug.zig");
const log = @import("std").log;

// order can also be seen in idt.asm
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

fn trapInterruptDump(cpu_state: *const cpuState) callconv(.C) void {
    const err_msg = switch (cpu_state.interrupt_id) {
        0 => "Division by zero\n",
        1 => "Debug\n",
        2 => "Non maskable interrupt\n",
        3 => "Breakpoint\n",
        4 => "Overflow\n",
        5 => "Bound range exceeded\n",
        6 => "Invalid opcode\n",
        7 => "Device not available\n",
        8 => "Double fault\n",
        9 => "Coprocessor segment overrun\n",
        10 => "Invalid TSS\n",
        11 => "Segment not present\n",
        12 => "Stack segment fault\n",
        13 => "General protection fault\n",
        14 => "Page fault\n",
        15 => "Reserved\n",
        16 => "x87 floating point exception\n",
        17 => "Alignment check\n",
        18 => "Machine check\n",
        19 => "SIMD floating point exception\n",
        20 => "Virtualization exception\n",
        21 => "Control protection exception\n",
        22...31 => "Reserved\n",
        else => "Unknown trap gate caught\n",
    };
    log.debug("{s}interrupt {d} caught: {s}CPU state:\n{any}\n\n", .{ (if (cpu_state.interrupt_id <= 31) "Hardware " else ""), cpu_state.interrupt_id, err_msg, cpu_state.* });

    log.warn("halting cpu...\n", .{});
    asm volatile ("hlt");
}
comptime {
    // global export with the name used inside idt.asm
    @export(&trapInterruptDump, .{ .name = "interrupt_trap_handler", .linkage = .strong });
}

pub fn init() void {}
