const std = @import("std");
const fmt = std.fmt;
const Writer = std.io.Writer;
const io = @import("io.zig");
const debug = @import("../debug.zig");
const keyboard = @import("keyboard.zig");

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

pub const ConsoleColors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

var row: usize = 0;
var column: usize = 0;
var color = vgaEntryColor(ConsoleColors.LightGray, ConsoleColors.Black);
var buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

fn vgaEntryColor(fg: ConsoleColors, bg: ConsoleColors) u8 {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

extern fn vgaEntry(uc: u8, new_color: u8) callconv(.C) u16;

pub fn initialize() void {
    clear();
}

pub fn setColor(new_color: u8) void {
    color = new_color;
}

pub fn clear() void {
    @memset(buffer[0..VGA_SIZE], vgaEntry(' ', color));
}

pub fn updateCursor() void {
    const index: u16 = @truncate(row * VGA_WIDTH + column);

    io.outb(0x3d4, 0x0f);
    io.outb(0x3D5, @as(u8, @truncate(index & 0xFF)));
    io.outb(0x3D4, 0x0E);
    io.outb(0x3D5, @as(u8, @truncate((index >> 8) & 0xFF)));
}

pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(c, new_color);
}

pub fn putChar(c: u8) callconv(.C) void {
    defer updateCursor();

    switch (c) {
        '\n' => {
            column = 0;
            row += 1;
            return;
        },
        '\t' => {
            for (0..4) |_| {
                putChar(' ');
            }
            return;
        },
        else => putCharAt(c, color, column, row),
    }

    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}

pub fn moveBack() void {
    if (column == 0) {
        column = VGA_WIDTH - 1;
        if (row == 0) {
            row = VGA_HEIGHT - 1;
        } else {
            row -= 1;
        }
    } else {
        column -= 1;
    }
    putCharAt(' ', color, column, row);
    updateCursor();
}

pub fn changeColumn(amount: isize) void {
    if (amount >= 0) {
        const new_column = column + @as(usize, @intCast(amount));
        if (new_column >= VGA_WIDTH) {
            column = VGA_WIDTH - 1;
        } else {
            column = new_column;
        }
    } else {
        const abs_amount = @as(usize, @intCast(-amount));
        if (abs_amount > column) {
            column = 0;
        } else {
            column -= abs_amount;
        }
    }
    updateCursor();
}

pub fn changeRow(amount: isize) void {
    if (amount >= 0) {
        const new_row = row + @as(usize, @intCast(amount));
        if (new_row >= VGA_HEIGHT) {
            row = VGA_HEIGHT - 1;
        } else {
            row = new_row;
        }
    } else {
        const abs_amount = @as(usize, @intCast(-amount));
        if (abs_amount > row) {
            row = 0;
        } else {
            row -= abs_amount;
        }
    }
    updateCursor();
}

pub fn puts(data: []const u8) void {
    for (data) |c| {
        if (c == '\n') {
            column = 0;
            row += 1;
        } else {
            putChar(c);
        }
    }
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}
