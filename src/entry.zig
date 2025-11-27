const paging = @import("arch/x86/paging.zig");
const kmain = @import("main.zig").kmain;

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

pub export var stack_bottom: [16 * 4096]u8 align(16) linksection(".bss") = undefined;
pub export var stack_top = &stack_bottom[stack_bottom.len - 4];

/// 0xC0000000 - start of kernel in virtual memory
/// 22 - starting bit of addr in a PDE
const first_kernel_dir = 0xC0000000 >> 22;
export var boot_page_table align(4096) linksection(".boot") = init: {
    @setEvalBranchQuota(1024);
    var dir: paging.PageTable = undefined;

    const kernel_page = paging.PageTableEntry{
        .present = 1,
        .permission = .readwrite,
        .access = .supervisor,
        .page_write_through = 0,
        .page_cache_disable = 0,
        .page_size = .@"4 MiB",
        .physical_addr = 0,
    };

    dir[0] = kernel_page;

    var idx = 1;
    for (0..first_kernel_dir - 1) |_| {
        dir[idx] = @bitCast(@as(u32, 0));
        idx += 1;
    }

    // map 0xC0000000 to 0xFFFFFFFF as kernel
    for (0..1024 - first_kernel_dir) |i| {
        dir[idx] = kernel_page;
        dir[idx].physical_addr = @truncate(i << 10);
        idx += 1;
    }

    break :init dir;
};

export fn _start() align(16) linksection(".boot") callconv(.naked) noreturn {
    // set up page directory,
    // turning on 4 MiB pages
    // and enabling paging
    asm volatile (
        \\ mov %ecx, %cr3
        \\
        \\ mov %cr4, %ecx
        \\ or $0x00000010, %ecx
        \\ mov %ecx, %cr4
        \\
        \\ mov %cr0, %ecx
        \\ or $0x80000000, %ecx
        \\ mov %ecx, %cr0
        \\
        \\ mov %eax, %ebx
        :
        : [boot_page_table] "{ecx}" (&boot_page_table),
        : "ecx"
    );

    asm volatile ("jmp higher_half_kernel");
    while (true) {}
}

export fn higher_half_kernel() align(16) callconv(.naked) noreturn {
    asm volatile (
        \\ mov %[stack_top], %esp
        \\ jmp %[kmain:P]
        :
        : [stack_top] "{edx}" (stack_top),
          [kmain] "X" (&kmain),
    );

    while (true) {}
}
