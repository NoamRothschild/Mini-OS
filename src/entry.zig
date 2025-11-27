const multiboot2_header_magic = 0xe85250d6;
const grub_multiboot_architecture_i386 = 0;

pub const MultiBootHeaderV2 = extern struct {
    magic: u32 = multiboot2_header_magic,
    arch: u32 = grub_multiboot_architecture_i386,
    len: u32 = @sizeOf(MultiBootHeaderV2),
    checksum: u32 = 0x100000000 - (multiboot2_header_magic + grub_multiboot_architecture_i386 + @sizeOf(MultiBootHeaderV2)),
    end_tag: u64 = 8 << 32,
};

export const multiboot_header: MultiBootHeaderV2 align(4) linksection(".multiboot") = .{};

export var stack_bottom: [16 * 4096]u8 align(16) linksection(".bss") = undefined;
const stack_top = &stack_bottom[stack_bottom.len - 4];

export fn _start() align(16) linksection(".boot") callconv(.naked) noreturn {
    asm volatile ("mov %[stack_top], %esp"
        :
        : [stack_top] "{edx}" (stack_top),
    );

    const screen: [*]volatile u16 = @ptrFromInt(0xB8000);

    const color: u16 = 2 | (0 << 4);
    screen[0] = @as(u16, 'O') | (color << 8);
    screen[1] = @as(u16, 'K') | (color << 8);

    while (true) {}
}
