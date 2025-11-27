const std = @import("std");
const debug = @import("debug.zig");
const io = @import("arch/x86/io.zig");
const vga = @import("drivers/vga.zig");

comptime {
    _ = @import("entry.zig");
}

pub fn kmain() callconv(.C) noreturn {
    vga.init();
    vga.print("vga screen initialized!\n", .{});

    while (true) {}
}

pub const panic = @import("debug.zig").panic;
