const std = @import("std");
const gdt = @import("gdt.zig");
const debug = @import("../debug.zig");

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

var idt_descriptor = Descriptor{
    .size = entries.len * @sizeOf(SegmentDescriptor) - 1,
    .start = undefined,
};

fn trapIsrDump(id: u32) callconv(.C) void {
    switch (id) {
        0 => debug.printf("Int {d} caught: Division by zero\n", .{id}),
        1 => debug.printf("Int {d} caught: Debug\n", .{id}),
        2 => debug.printf("Int {d} caught: Non maskable interrupt\n", .{id}),
        3 => debug.printf("Int {d} caught: Breakpoint\n", .{id}),
        4 => debug.printf("Int {d} caught: Overflow\n", .{id}),
        5 => debug.printf("Int {d} caught: Bound range exceeded\n", .{id}),
        6 => debug.printf("Int {d} caught: Invalid opcode\n", .{id}),
        7 => debug.printf("Int {d} caught: Device not available\n", .{id}),
        8 => debug.printf("Int {d} caught: Double fault\n", .{id}),
        9 => debug.printf("Int {d} caught: Coprocessor segment overrun\n", .{id}),
        10 => debug.printf("Int {d} caught: Invalid TSS\n", .{id}),
        11 => debug.printf("Int {d} caught: Segment not present\n", .{id}),
        12 => debug.printf("Int {d} caught: Stack segment fault\n", .{id}),
        13 => debug.printf("Int {d} caught: General protection fault\n", .{id}),
        14 => debug.printf("Int {d} caught: Page fault\n", .{id}),
        15 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        16 => debug.printf("Int {d} caught: x87 floating point exception\n", .{id}),
        17 => debug.printf("Int {d} caught: Alignment check\n", .{id}),
        18 => debug.printf("Int {d} caught: Machine check\n", .{id}),
        19 => debug.printf("Int {d} caught: SIMD floating point exception\n", .{id}),
        20 => debug.printf("Int {d} caught: Virtualization exception\n", .{id}),
        21 => debug.printf("Int {d} caught: Control protection exception\n", .{id}),
        22 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        23 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        24 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        25 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        26 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        27 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        28 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        29 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        30 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        31 => debug.printf("Int {d} caught: Reserved\n", .{id}),
        else => debug.printf("Unknown trap gate caught with id {d}\n", .{id}),
    }
}
comptime {
    @export(&trapIsrDump, .{ .name = "idt_trap_handler", .linkage = .strong });
}
/// given an index, return a corresponding function ptr that when called will execute defaultIsr(index)
extern fn idt_entryFuncByIndex(index: u32) callconv(.C) u32;

inline fn initTable() void {
    // const interrupt_gate = makeState(.{
    //     .offset = @intFromPtr(defaultIsr),
    //     .segment_selector = .{
    //         .index = gdt.offsets.kernel_codeseg,
    //         .rpl = 0x0, // TODO: Check if does not conflict with dpl somehow
    //         .ti = 0,
    //     },
    //     .gate_type = gate_types.intr_gate32bit,
    //     .dpl = 0x3, // everyone can call these interrupts using `int`
    //     .p = 1,
    // });

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
}

pub fn init() void {
    idt_descriptor.start = &entries;
    initTable();

    asm volatile (
        \\ lidt (%eax)
        :
        : [IDT_Descriptor] "{eax}" (&idt_descriptor),
        : "eax"
    );
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
