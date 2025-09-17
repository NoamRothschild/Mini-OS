const std = @import("std");
const log = std.log;
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

extern var stack_top: [*]u32;
extern var stack_len: u32;

pub const panic = std.debug.FullPanic(panicFn);

fn panicFn(err: []const u8, ra: ?usize) noreturn {
    @branchHint(.cold);
    _ = ra;

    printf("PANIC!: {s}\n", .{err});
    printf("return address: 0x{X} frame address: 0x{X}\n", .{ @returnAddress(), @frameAddress() });
    printf("stack starts at: 0x{X} end: 0x{X}\n", .{
        @intFromPtr(&stack_top[0]),
        @intFromPtr(&stack_top[0]) + stack_len,
    });

    while (true) {}
}

pub fn logFn(
    comptime message_level: log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    const prefix = switch (message_level) {
        .debug => "[debug] ",
        .err => "[err] ",
        .info => "[info] ",
        .warn => "[warn] ",
    };
    printf("{s}", .{prefix});
    printf(format, args);
}
