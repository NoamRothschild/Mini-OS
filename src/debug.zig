const std = @import("std");
pub const COM1 = 0x03F8;

pub fn outb(port: u16, byte: u8) void {
    asm volatile (
        \\ mov %[port], %dx
        \\ mov %[byte], %al
        \\ out %al, %dx
        :
        : [port] "{dx}" (port),
          [byte] "{al}" (byte),
        : "al", "dx"
    );
}

pub const outWriter = std.io.Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    for (string) |char| {
        outb(COM1, char);
    }
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    std.fmt.format(outWriter, format, args) catch unreachable;
}
