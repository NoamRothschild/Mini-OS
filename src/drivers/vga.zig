const std = @import("std");
const io = @import("../arch/x86/io.zig");

const vga_width = 80;
const vga_height = 25;
const vga_size = vga_width * vga_height;

var g_row: usize = 0;
var g_column: usize = 0;
var g_color: Color = .init(.light_gray, .black);
var g_buffer: [*]volatile u16 = @ptrFromInt(0xB8000);

pub const ColorType = enum(u4) {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_gray = 7,
    dark_gray = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    light_brown = 14,
    white = 15,
};

const Color = packed struct(u8) {
    fg: ColorType,
    bg: ColorType,

    pub fn init(fg: ColorType, bg: ColorType) Color {
        return .{ .fg = fg, .bg = bg };
    }

    /// Combine vga color and char. The upper byte will be color and lower byte will be character
    pub inline fn getVgaChar(self: Color, char: u8) u16 {
        return @as(u16, @as(u8, @bitCast(self))) << 8 | char;
    }
};

/// Initialize VGA
pub fn init() void {
    clear();
}

/// Set Color for VGA
pub fn setColor(fg: Color, bg: Color) void {
    g_color = Color.init(fg, bg);
}

/// Clear the screen
pub fn clear() void {
    @memset(g_buffer[0..vga_size], Color.getVgaChar(g_color, ' '));
}

pub fn putCharAt(char: u8, color: Color, x: usize, y: usize) void {
    const index = y * vga_width + x;
    g_buffer[index] = color.getVgaChar(char);
}

pub fn putChar(c: u8) void {
    switch (c) {
        '\n' => {
            g_column = 0;
            g_row += 1;
            return;
        },
        '\t' => {
            for (0..4) |_| {
                putChar(' ');
            }
            return;
        },
        else => putCharAt(c, g_color, g_column, g_row),
    }

    g_column += 1;
    if (g_column == vga_width) {
        g_column = 0;
        g_row += 1;
        if (g_row == vga_height)
            g_row = 0;
    }
}

pub fn puts(data: []const u8) void {
    for (data) |c|
        putChar(c);
    setCursor(g_column, g_row);
}

pub fn setCursor(x: usize, y: usize) void {
    const index: u16 = @truncate(y *% vga_width +% x);

    io.outb(0x3d4, 0x0f);
    io.outb(0x3D5, @as(u8, @truncate(index & 0xFF)));
    io.outb(0x3D4, 0x0E);
    io.outb(0x3D5, @as(u8, @truncate((index >> 8) & 0xFF)));
}

pub const writer = std.io.Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(writer, format, args) catch unreachable;
}
