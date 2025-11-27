pub inline fn outb(port: u16, byte: u8) void {
    asm volatile (
        \\ mov %[port], %dx
        \\ mov %[byte], %al
        \\ out %al, %dx
        :
        : [port] "{dx}" (port),
          [byte] "{al}" (byte),
        : "al", "dx"
    );
}

pub inline fn inb(port: u16) u8 {
    var ret: u8 = undefined;
    asm volatile ("inb %[port], %[ret]"
        : [ret] "={al}" (ret),
        : [port] "{dx}" (port),
    );
    return ret;
}

pub inline fn wait() void {
    outb(0x80, 0);
}
