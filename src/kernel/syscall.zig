const std = @import("std");
const log = std.log;
const debug = @import("../debug.zig");
const cpuState = @import("interrupts.zig").cpuState;

pub export const syscall_number: u32 = 0x90; // 144 :)
pub extern fn syscall_handler() callconv(.C) void; // this is the wrapper, setting up the cpu state and returninig with `iret`
// it calls syscallHandler(esp -> cpuState)

export fn syscallHandler(cpu_state: *const cpuState) void {
    log.debug("Syscall called!:\n{any}\n\n", .{cpu_state.*});
}

pub fn init() void {}
