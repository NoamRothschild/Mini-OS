const io = @import("io.zig");
const cpuState = @import("interrupts.zig").cpuState;
const debug = @import("../debug.zig");
const timer = @import("timer.zig");
const keyboard = @import("keyboard.zig");

const pic_master_offset: u8 = 0x20;
const pic_slave_offset: u8 = 0x28;

const pic1: u16 = 0x20; // IO base address for master PIC
const pic2: u16 = 0xA0; // IO base address for slave PIC
const pic1_command: u16 = pic1;
const pic1_data: u16 = pic1 + 1;
const pic2_command: u16 = pic2;
const pic2_data: u16 = pic2 + 1;
const pic_eoi: u16 = 0x20; // End-of-interrupt command code

const icw1_icw4: u16 = 0x01; // Indicates that ICW4 will be present
const icw1_single: u16 = 0x02; // Single (cascade) mode
const icw1_interval4: u16 = 0x04; // Call address interval 4 (8)
const icw1_level: u16 = 0x08; // Level triggered (edge) mode
const icw1_init: u16 = 0x10; // Initialization - required!

const icw4_8086: u16 = 0x01; // 8086/88 (MCS-80/85) mode
const icw4_auto: u16 = 0x02; // Auto (normal) EOI
const icw4_buf_slave: u16 = 0x08; // Buffered mode/slave
const icw4_buf_master: u16 = 0x0C; // Buffered mode/master
const icw4_sfnm: u16 = 0x10; // Special fully nested (not)

const cascade_irq: u16 = 2;

pub fn remap(master_offset: u8, slave_offset: u8) void {
    io.outb(pic1_command, icw1_init | icw1_icw4); // starts the initialization sequence (in cascade mode)
    io.wait();
    io.outb(pic2_command, icw1_init | icw1_icw4);
    io.wait();
    io.outb(pic1_data, master_offset); // ICW2: Master PIC vector offset
    io.wait();
    io.outb(pic2_data, slave_offset); // ICW2: Slave PIC vector offset
    io.wait();
    io.outb(pic1_data, 1 << cascade_irq); // ICW3: tell Master PIC that there is a slave PIC at IRQ2
    io.wait();
    io.outb(pic2_data, 2); // ICW3: tell Slave PIC its cascade identity (0000 0010)
    io.wait();

    io.outb(pic1_data, icw4_8086); // ICW4: have the PICs use 8086 mode (and not 8080 mode)
    io.wait();
    io.outb(pic2_data, icw4_8086);
    io.wait();

    // Unmask both pics.
    io.outb(pic1_data, 0);
    io.outb(pic2_data, 0);
}

pub fn init() void {
    remap(pic_master_offset, pic_slave_offset);
}

export fn irqHandler(cpu_state: *cpuState) callconv(.C) void {
    const irq_id = cpu_state.*.interrupt_id - 32; // [0..16)
    defer {
        if (irq_id >= 8) {
            io.outb(pic_slave_offset, pic_eoi);
        }
        io.outb(pic_master_offset, pic_eoi);
    }
    switch (irq_id) {
        0 => timer.callback(),
        1 => keyboard.callback(),
        else => {
            debug.printf("an irq has been called from pic number {d}\n", .{irq_id});

            debug.printf("cpu state: {any}\n\n", .{cpu_state.*});
        },
    }
}
