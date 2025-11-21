const io = @import("io.zig");
const console = @import("console.zig");
const debug = @import("../debug.zig");
const std = @import("std");
const log = std.log;

const data_port = 0x60;
const control_port = 0x64;
pub var key_states: [128]?KeyState = .{null} ** 128;
var is_caps_on: bool = false;

pub const scancodes = struct {
    shift: u8 = 54,
    alt: u8 = 56,
    ctrl: u8 = 59,
    backspace: u8 = 14,
    caps_lock: u8 = 58,
    arrow_up: u8 = 72,
    arrow_down: u8 = 80,
    arrow_left: u8 = 75,
    arrow_right: u8 = 77,
}{};

const Key = struct {
    state: KeyState,
    scancode: u8,
};

const KeyState = enum(u1) {
    pressed,
    released,

    fn fromScancode(sc: u8) KeyState {
        return if (sc & 0x80 == 0) .pressed else .released;
    }
};

pub fn callback() void {
    log.debug("key pressed: ", .{});
    const scancode: u8 = io.inb(data_port);
    const state = KeyState.fromScancode(scancode);
    const scancode_flat = scancode & (~@as(u8, 0x80));
    key_states[scancode_flat] = state;
    defer {
        if (state == .released)
            key_states[scancode_flat] = null;
    }
    if (scancode_flat == scancodes.caps_lock and state == .pressed)
        is_caps_on = !is_caps_on;

    log.debug("{d}, {s}\n", .{ scancode_flat, if (state == .pressed) "pressed" else "released" });
    if (state == .pressed) {
        switch (scancode_flat) {
            scancodes.arrow_up => console.changeRow(-1),
            scancodes.arrow_down => console.changeRow(1),
            scancodes.arrow_left => console.changeColumn(-1),
            scancodes.arrow_right => console.changeColumn(1),
            scancodes.backspace => console.moveBack(),
            else => {
                if (scancodeToChar(scancode)) |c| {
                    if (key_states[scancodes.shift]) |_| {
                        console.putChar(getShiftChar(c));
                        return;
                    }
                    if (is_caps_on) {
                        console.putChar(std.ascii.toUpper(c));
                        return;
                    }
                    console.putChar(c);
                } else |_| {}
            },
        }
    }
}

pub fn scancodeToChar(scancode: u8) error{notPrintable}!u8 {
    return switch (scancode & (~@as(u8, 0x80))) {
        1 => 27,
        2...10 => '1' + (scancode - 2),
        11 => '0',
        12 => '-',
        13 => '=',
        15 => '\t',
        16 => 'q',
        17 => 'w',
        18 => 'e',
        19 => 'r',
        20 => 't',
        21 => 'y',
        22 => 'u',
        23 => 'i',
        24 => 'o',
        25 => 'p',
        26 => '[',
        27 => ']',
        28 => '\n',
        30 => 'a',
        31 => 's',
        32 => 'd',
        33 => 'f',
        34 => 'g',
        35 => 'h',
        36 => 'j',
        37 => 'k',
        38 => 'l',
        39 => ';',
        40 => '\'',
        41 => '`',
        43 => '\\',
        44 => 'z',
        45 => 'x',
        46 => 'c',
        47 => 'v',
        48 => 'b',
        49 => 'n',
        50 => 'm',
        51 => ',',
        52 => '.',
        53 => '/',
        55 => '*',
        57 => ' ',
        74 => '-',
        78 => '+',
        else => error.notPrintable,
    };
}

fn getShiftChar(c: u8) u8 {
    return switch (c) {
        '0' => ')',
        '1' => '!',
        '2' => '@',
        '3' => '#',
        '4' => '$',
        '5' => '%',
        '6' => '^',
        '7' => '&',
        '8' => '*',
        '9' => '(',
        '-' => '_',
        '=' => '+',
        '[' => '{',
        ']' => '}',
        '\\' => '|',
        ';' => ':',
        '\'' => '"',
        '`' => '~',
        ',' => '<',
        '.' => '>',
        '/' => '?',
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
        'd' => 'D',
        'e' => 'E',
        'f' => 'F',
        'g' => 'G',
        'h' => 'H',
        'i' => 'I',
        'j' => 'J',
        'k' => 'K',
        'l' => 'L',
        'm' => 'M',
        'n' => 'N',
        'o' => 'O',
        'p' => 'P',
        'q' => 'Q',
        'r' => 'R',
        's' => 'S',
        't' => 'T',
        'u' => 'U',
        'v' => 'V',
        'w' => 'W',
        'x' => 'X',
        'y' => 'Y',
        'z' => 'Z',
        else => c,
    };
}
