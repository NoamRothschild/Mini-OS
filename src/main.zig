const console = @import("kernel/console.zig");
const config = @import("config.zig");
const gdt = @import("kernel/gdt.zig");
const idt = @import("kernel/idt.zig");
const timer = @import("kernel/timer.zig");
const debug = @import("debug.zig");
const std = @import("std");

extern var stack_len: u32;

fn infoPrint(str: []const u8) void {
    console.printf("{s}\n", .{str});
    debug.printf("{s}\n", .{str});
}

pub export fn kmain() callconv(.C) void {
    console.initialize();
    console.printf("Hello {s}, {d}\n", .{ "world", stack_len });

    gdt.init();
    infoPrint("GDT Initialized");

    const frequency = 50; // the higher the freq, the more times the timer callback gets called
    timer.init(frequency);
    infoPrint("Timer Initialized");

    idt.init();
    infoPrint("IDT Initialized");

    debug.printf("CPU vendor: {s}\n", .{debug.getVendor()});

    debug.printf("features: {any}\n", .{debug.getFeatures()});

    debug.printf("testing irq handler is working... ", .{});
    asm volatile (
        \\ int $36
    );

    debug.printf("running a syscall... ", .{});
    asm volatile (
        \\ mov $12, %eax
        \\ int $144
    );

    while (true) {}

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
