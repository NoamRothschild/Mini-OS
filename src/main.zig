const console = @import("kernel/console.zig");
const config = @import("config.zig");
const gdt = @import("kernel/gdt.zig");
const idt = @import("kernel/idt.zig");
const debug = @import("debug.zig");

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

    // asm volatile ("int $0x80");
    asm volatile ("int $0x12");
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
