const std = @import("std");
const debug = @import("debug.zig");
const io = @import("arch/x86/io.zig");
const vga = @import("drivers/vga.zig");
const mem = @import("mem/heap.zig");

comptime {
    _ = @import("entry.zig");
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
    vga.print("{s}\n", .{msg});
}

pub fn kmain() !void {
    vga.init();
    vgaOKPrint("VGA mode initialized");

    @panic("intentional panic");
}

pub const panic = @import("debug.zig").panic;
pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = debug.logFn,
};
