const console = @import("console/root.zig");
const config = @import("config.zig");

extern var stack_len: u32;

pub export fn kmain() callconv(.C) void {
    console.initialize();
    console.printf("Hello {s}, {d}", .{ "world", stack_len });

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
