const std = @import("std");
// Tried to print text before running certain commands

// inconsistent :SOB:
fn prependText(b: *std.Build, the_step: *std.Build.Step, text: []const u8) void {
    const text_step = b.addSystemCommand(&[_][]const u8{ "echo", b.fmt("info: {s}", .{text}) });
    the_step.dependOn(&text_step.step);
}

// too cursed :SOB:, I guess no printing
fn systemCommandPrefixed(b: *std.Build, text: []const u8, cmd: []const u8) *std.Build.Step.Run {
    const sanetized_text = blk: {
        var to_escape_count: usize = 0;
        for (text) |c| {
            if (c == '\'') to_escape_count += 1;
        }
        if (to_escape_count == 0) break :blk text;

        const sanetized_length = text.len + to_escape_count * 3;
        var sanetized = b.allocator.alloc(u8, sanetized_length) catch unreachable;
        var idx: usize = 0;
        for (text) |c| {
            if (c == '\'') {
                sanetized[idx] = '\'';
                sanetized[idx + 1] = '\\';
                sanetized[idx + 2] = '\'';
                sanetized[idx + 3] = '\'';
                idx += 4;
            } else {
                sanetized[idx] = c;
                idx += 1;
            }
        }
        break :blk sanetized;
    };

    const sh_cmd = b.fmt("echo '{s}' && {s}", .{ sanetized_text, cmd });
    return b.addSystemCommand(&[_][]const u8{ "sh", "-c", sh_cmd });
}
