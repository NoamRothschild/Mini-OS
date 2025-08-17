const std = @import("std");

const Access = packed struct {
    // Accessed (CPU sets to 1 when segment is accessed)
    a: u1 = 0,

    // Readable (for code segments) / Writable (for data segments)
    //  Code: 1 = readable, 0 = exec-only
    //  Data: 1 = writable, 0 = read-only
    rw: u1 = 0,

    // Direction (for data) / Conforming (for code)
    //  Data: 0 = grows up, 1 = grows down
    //  Code: 0 = only at same privilege, 1 = lower privilege allowed
    dc: u1 = 0,

    // Executable (0 = data segment, 1 = code segment)
    e: u1 = 0,

    // Descriptor type (0 = system, 1 = code/data)
    s: u1 = 0,

    // Descriptor Privilege Level (0 = kernel, 3 = user)
    dpl: u2 = 0,

    // Present bit (1 = segment is present in memory)
    p: u1 = 0,
};

const kernel_code_access: Access = .{ .p = 1, .dpl = 0, .s = 1, .e = 1, .dc = 0, .rw = 1, .a = 0 };
const kernel_data_access: Access = .{ .p = 1, .dpl = 0, .s = 1, .e = 0, .dc = 0, .rw = 1, .a = 0 };
const task_state_access: Access = .{ .p = 1, .dpl = 0, .s = 0, .e = 1, .dc = 0, .rw = 0, .a = 1 };

pub const SegmentDescriptor = packed struct {
    limit_low: u16,
    base_low: u24,
    access: Access,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

var entries: [3]SegmentDescriptor = undefined;

pub const descriptor = packed struct {
    size: u16,
    start: [*]SegmentDescriptor,
};

var gdt_descriptor = descriptor{
    .size = entries.len * @sizeOf(SegmentDescriptor) - 1,
    .start = undefined,
};

inline fn setTable() void {
    // Null Descriptor
    entries[0] = makeState(.{
        .base = 0,
        .limit = 0,
        .access = .{},
        .flags = 0,
    });

    // Kernel Mode Code Segment
    entries[1] = makeState(.{
        .base = 0x00000000,
        .limit = 0xFFFFF,
        .access = kernel_code_access,
        .flags = 0xC,
    });

    // Kernel Mode Data Segment
    entries[2] = makeState(.{
        .base = 0x00000000,
        .limit = 0xFFFFF,
        .access = kernel_data_access,
        .flags = 0xC,
    });
}

pub fn init() void {
    gdt_descriptor.start = &entries;
    setTable();

    asm volatile (
        \\ lgdt (%eax)
        \\
        \\ mov $0x10, %ax
        \\ mov %ax, %ds
        \\ mov %ax, %es
        \\ mov %ax, %fs
        \\ mov %ax, %gs
        \\ mov %ax, %ss
        \\ ljmp $0x08, $1f
        \\ 1:
        :
        : [GDT_Descriptor] "{eax}" (&gdt_descriptor),
        : "eax"
    );
}

fn makeState(config: struct { limit: u20, base: u32, access: Access, flags: u4 }) SegmentDescriptor {
    return SegmentDescriptor{
        .base_low = @truncate(config.base),
        .base_high = @truncate(config.base >> 24),
        .limit_low = @truncate(config.limit),
        .limit_high = @truncate(config.limit >> 16),
        .access = config.access,
        .flags = config.flags,
    };
}

/// returns the offset of each segment based on its index in the table
fn offsetAt(entry_index: usize) usize {
    return entry_index * 8;
}
