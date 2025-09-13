const std = @import("std");
const io = @import("kernel/io.zig");
pub const COM1 = 0x03F8;

pub const outWriter = std.io.Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    for (string) |char| {
        io.outb(COM1, char);
    }
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    std.fmt.format(outWriter, format, args) catch unreachable;
}
