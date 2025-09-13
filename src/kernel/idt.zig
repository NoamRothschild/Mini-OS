const std = @import("std");
const gdt = @import("gdt.zig");
const debug = @import("../debug.zig");
const syscall = @import("syscall.zig");

pub const SegmentSelector = packed struct {
    rpl: u2,
    ti: u1,
    index: u13,
};

pub const SegmentDescriptor = packed struct {
    offset_1: u16,
    segment_selector: SegmentSelector,
    reserved: u8,
    gate_type: u4,
    zero: u1,
    dpl: u2,
    p: u1,
    offset_2: u16,
};

const gate_types = struct {
    task_gate: u4 = 0x5,
    intr_gate16bit: u4 = 0x6,
    trap_gate16bit: u4 = 0x7,
    intr_gate32bit: u4 = 0xe,
    trap_gate32bit: u4 = 0xf,
}{};

var entries: [0xff]SegmentDescriptor = undefined;

pub const Descriptor = packed struct {
    size: u16,
    start: [*]SegmentDescriptor,
};
comptime {
    const size = @bitSizeOf(Descriptor);

    if (size != 48)
        @compileError(std.fmt.comptimePrint("[*] SegmentDescriptor inside Descriptor definition expanded to unexpected size: {d}", .{@bitSizeOf(Descriptor) - 16}));
}

var idt_descriptor = Descriptor{
    .size = entries.len * @sizeOf(SegmentDescriptor) - 1,
    .start = undefined,
};

/// given an index, return a corresponding function ptr that when called will execute defaultIsr(index)
extern fn idt_entryFuncByIndex(index: u32) callconv(.C) u32;
extern fn idt_irqByIndex(index: u32) callconv(.C) u32;

inline fn initTable() void {
    const syscall_gate = makeState(.{
        .offset = @intFromPtr(&syscall.syscall_handler),
        .segment_selector = .{
            .index = gdt.offsets.kernel_codeseg,
            .rpl = 0x0, // TODO: Check if does not conflict with dpl somehow
            .ti = 0,
        },
        .gate_type = gate_types.intr_gate32bit,
        .dpl = 0x3, // everyone can call these interrupts using `int`
        .p = 1,
    });

    // const task_gate = makeState(.{
    //     .offset = 0,
    //     .segment_selector = .{
    //         .index = gdt.offsets.tss,
    //         .rpl = 0x0, // TODO: Check if does not conflict with dpl somehow
    //         .ti = 0,
    //     },
    //     .gate_type = gate_types.task_gate,
    //     .dpl = 0x3, // everyone can call these interrupts using `int`
    //     .p = 1,
    // });

    // trap gates
    for (0..32) |i|
        entries[i] = makeState(.{
            .offset = idt_entryFuncByIndex(i),
            .segment_selector = .{
                .index = gdt.offsets.kernel_codeseg,
                .rpl = 0x0,
                .ti = 0,
            },
            .gate_type = gate_types.trap_gate32bit,
            .dpl = 0x0,
            .p = 1,
        });

    for (0..16) |i|
        entries[i + 32] = makeState(.{
            .offset = idt_irqByIndex(i),
            .segment_selector = .{
                .index = gdt.offsets.kernel_codeseg,
                .rpl = 0x0,
                .ti = 0,
            },
            .gate_type = gate_types.intr_gate32bit,
            .dpl = 0x0,
            .p = 1,
        });

    entries[syscall.syscall_number] = syscall_gate;
}

pub fn init() void {
    @import("interrupts.zig").init(); // currently here to force add file to compilation
    @import("syscall.zig").init(); // currently here to force add file to compilation
    @import("pic.zig").init(); // remaps pic ports to gates 32-47

    idt_descriptor.start = &entries;
    initTable();

    asm volatile (
        \\ lidt (%eax)
        :
        : [IDT_Descriptor] "{eax}" (&idt_descriptor),
        : "eax"
    );

    // enable interrupts
    asm volatile ("sti");
}

fn makeState(config: struct { offset: u32, segment_selector: SegmentSelector, gate_type: u4, dpl: u2, p: u1 }) SegmentDescriptor {
    return SegmentDescriptor{
        .offset_1 = @truncate(config.offset),
        .segment_selector = config.segment_selector,
        .reserved = 0,
        .gate_type = config.gate_type,
        .zero = 0,
        .dpl = config.dpl,
        .p = config.p,
        .offset_2 = @truncate(config.offset >> 16),
    };
}
