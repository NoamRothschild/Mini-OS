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

pub const Tss = packed struct {
    link: u16,
    _reserved1: u16,
    esp0: u32,
    ss0: u16,
    _reserved2: u16,
    esp1: u32,
    ss1: u16,
    _reserved3: u16,
    esp2: u32,
    ss2: u16,
    _reserved4: u16,
    cr3: u32,
    eip: u32,
    eflags: u32,
    eax: u32,
    ecx: u32,
    edx: u32,
    ebx: u32,
    esp: u32,
    ebp: u32,
    esi: u32,
    edi: u32,
    es: u16,
    _reserved5: u16,
    cs: u16,
    _reserved6: u16,
    ss: u16,
    _reserved7: u16,
    ds: u16,
    _reserved8: u16,
    fs: u16,
    _reserved9: u16,
    gs: u16,
    _reserved10: u16,
    ldtr: u16,
    _reserved11: u32,
    iopb: u16,
    ssp: u32,
};

var entries: [4]SegmentDescriptor = undefined;
var tss_entry = std.mem.zeroes(Tss);

pub const Descriptor = packed struct {
    size: u16,
    start: [*]SegmentDescriptor,
};
comptime {
    const size = @bitSizeOf(Descriptor);

    if (size != 48)
        @compileError(std.fmt.comptimePrint("[*] SegmentDescriptor inside Descriptor definition expanded to unexpected size: {d}", .{@bitSizeOf(Descriptor) - 16}));
}

var gdt_descriptor = Descriptor{
    .size = entries.len * @sizeOf(SegmentDescriptor) - 1,
    .start = undefined,
};

pub const offsets = struct {
    nulld: usize = 0,
    kernel_codeseg: usize = 1,
    kernel_dataseg: usize = 2,
    tss: usize = 3,
}{};

fn tableOffsetOf(offset: usize) usize {
    return offset * 8;
}

extern var stack_top: u32;
inline fn initTable() void {
    // Null Descriptor
    entries[offsets.nulld] = makeState(.{
        .base = 0,
        .limit = 0,
        .access = .{},
        .flags = 0,
    });

    // Kernel Mode Code Segment
    entries[offsets.kernel_codeseg] = makeState(.{
        .base = 0x00000000,
        .limit = 0xFFFFF,
        .access = kernel_code_access,
        .flags = 0xC,
    });

    // Kernel Mode Data Segment
    entries[offsets.kernel_dataseg] = makeState(.{
        .base = 0x00000000,
        .limit = 0xFFFFF,
        .access = kernel_data_access,
        .flags = 0xC,
    });

    entries[offsets.tss] = makeState(.{
        .base = @intFromPtr(&tss_entry),
        .limit = @sizeOf(Tss) - 1,
        .access = task_state_access,
        .flags = 0x0,
    });

    tss_entry.ss0 = @truncate(tableOffsetOf(offsets.kernel_dataseg));
    tss_entry.esp0 = stack_top;
    tss_entry.iopb = @sizeOf(Tss);
}

pub fn init() void {
    gdt_descriptor.start = &entries;
    initTable();

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

    asm volatile (
        \\ mov %[tss_descriptor_offset], %ax
        \\ ltr %ax
        :
        : [tss_descriptor_offset] "i" (comptime tableOffsetOf(offsets.tss)),
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
