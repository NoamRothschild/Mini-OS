const console = @import("kernel/console.zig");
const config = @import("config.zig");
const gdt = @import("kernel/gdt.zig");
const idt = @import("kernel/idt.zig");
const timer = @import("kernel/timer.zig");
const debug = @import("debug.zig");
const std = @import("std");
const log = std.log;
const paging = @import("kernel/paging.zig");

extern var stack_len: u32;

fn infoPrint(str: []const u8) void {
    console.printf("{s}\n", .{str});
    log.info("{s}\n", .{str});
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

    paging.init();
    infoPrint("Paging initialized");

    log.info("kernel kmain: 0x{x:0>8}\n", .{@intFromPtr(&kmain)});

    log.debug("CPU vendor: {s}\n", .{debug.getVendor()});

    log.debug("features: {any}\n", .{debug.getFeatures()});

    log.debug("testing irq handler is working... ", .{});
    asm volatile (
        \\ int $36
    );

    log.debug("running a syscall... ", .{});
    asm volatile (
        \\ mov $12, %eax
        \\ int $144
    );

    while (true) {}

    log.debug("dividing by zero (testing cpu exception)... ", .{});
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

pub const panic = @import("debug.zig").panic;
pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = debug.logFn,
};
