const std = @import("std");
const debug = @import("debug.zig");
const io = @import("arch/x86/io.zig");
const vga = @import("drivers/vga.zig");
const gdt = @import("arch/x86/gdt.zig");
const idt = @import("arch/x86/idt.zig");
const interrupts = @import("arch/x86/interrupts.zig");
const cpuState = interrupts.cpuState;
const mem = @import("mem/heap.zig");

comptime {
    _ = @import("arch/x86/entry.zig");
}

fn vgaOKPrint(msg: []const u8) void {
    const og_color = vga.g_color;
    defer vga.g_color = og_color;

    vga.g_color = .init(.light_gray, .black);
    vga.puts("[ ");
    vga.g_color = .init(.green, .black);
    vga.puts("OK");
    vga.g_color = .init(.light_gray, .black);
    vga.puts(" ] ");
    vga.g_color = .init(.white, .black);
    vga.print("{s} initialized\n", .{msg});
}

pub fn kmain() !void {
    vga.init();
    vgaOKPrint("VGA mode");

    gdt.init();
    vgaOKPrint("GDT && TSS");

    idt.init();
    vgaOKPrint("IDT && interrupts");

    asm volatile (
        \\ xor %edx, %edx
        \\ xor %eax, %eax
        \\ int $144 // syscall
        \\ div %eax
    );

    while (true) {}
}

pub const panic = @import("debug.zig").panic;
pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = debug.logFn,
};
