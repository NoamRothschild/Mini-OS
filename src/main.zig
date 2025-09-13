const console = @import("kernel/console.zig");
const config = @import("config.zig");
const gdt = @import("kernel/gdt.zig");
const idt = @import("kernel/idt.zig");
const debug = @import("debug.zig");
const std = @import("std");

extern var stack_len: u32;

pub export fn kmain() callconv(.C) void {
    console.initialize();
    console.printf("Hello {s}, {d}\n", .{ "world", stack_len });

    gdt.init();
    console.printf("GDT Initialized!\n", .{});
    debug.printf("GDT Initialized\n", .{});

    idt.init();
    console.printf("IDT Initialized!\n", .{});
    debug.printf("IDT Initialized\n", .{});

    debug.printf("testing irq handler is working... ", .{});
    asm volatile (
        \\ int $33
    );

    debug.printf("running a syscall... ", .{});
    asm volatile (
        \\ mov $12, %eax
        \\ int $144
    );

    debug.printf("dividing by zero (testing cpu exception)... ", .{});
    asm volatile (
        \\ xor %ebx, %ebx
        \\ div %ebx
    );

    // const colored_char: u16 = console.vgaEntry('h', 3);

    // const video_memory = @as([*]volatile u16, @ptrFromInt(0x0B8000));
    // for (0..25) |y| {
    //     for (0..80) |x| {
    //         video_memory[(y * 80) + x] = colored_char;
    //     }
    // }

    // asm volatile (
    //     \\
    // );

    while (true) {}
}
