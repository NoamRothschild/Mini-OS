const paging = @import("paging.zig");
const root = @import("../../main.zig");
const debug = @import("../../debug.zig");

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

const higher_half_base = 0xC0000000;
const page_dir_idx_base = (higher_half_base >> 22);
const kernel_page_table_count = 1024 - page_dir_idx_base;

// we need to map 0xC0000000 to 0xFFFFFFFF as kernel
var page_tables: [kernel_page_table_count][1024]paging.PageTableEntry align(0x1000) linksection(".boot") = init: {
    @setEvalBranchQuota(1000000);
    var tables: [kernel_page_table_count][1024]paging.PageTableEntry = undefined;

    for (&tables, page_dir_idx_base..) |*page_table, pde_idx| {
        for (0..1024) |pte_idx| {
            page_table.*[pte_idx] = paging.kernel_table_page;
            page_table.*[pte_idx].physical_addr = @truncate(pte_idx | (pde_idx << 10) - (higher_half_base >> 12));
            // NOTE: we subtract higher_half_base to account for the LMA changes in the linker.ld like `AT(ADDR(.text) - 0xC0000000)`
        }
    }

    break :init tables;
};

// map the first 8 MB of memory (identity mapped)
var boot_page_tables: [2][1024]paging.PageTableEntry align(0x1000) linksection(".boot") = init: {
    @setEvalBranchQuota(1000000);

    var tables: [2][1024]paging.PageTableEntry = undefined;
    for (&tables, 0..) |*table, pde_idx| {
        for (0..1024) |pte_idx| {
            table[pte_idx] = paging.kernel_table_page;
            table[pte_idx].physical_addr = @truncate(pte_idx | pde_idx << 10);
            table[pte_idx].global = 1; // 'Global' tells the processor not to invalidate the TLB entry corresponding to the page upon a MOV to CR3 instruction.
            // // NOTE: I enabled Global here, but I don't think its system flag is enabled, so this does not do anything useful for now.
        }
    }

    break :init tables;
};

var page_directories: [1024]paging.PageDirectoryEntry align(0x1000) linksection(".boot") = undefined;

pub fn init_page_directories() linksection(".boot") callconv(.C) void {
    for (0..2) |i| {
        page_directories[i] = paging.kernel_directory_page;
        page_directories[i].page_table_physical_addr = @truncate(@intFromPtr(&boot_page_tables[i]) >> 12);
    }

    for (2..page_dir_idx_base - 1) |pde_idx| {
        const pde = &page_directories[pde_idx];
        pde.* = paging.non_present_directory_page;
    }

    for (page_dir_idx_base..1024) |pde_idx| {
        const pde = &page_directories[pde_idx];
        const page_table_addr = &page_tables[pde_idx - page_dir_idx_base];
        pde.* = paging.kernel_directory_page;
        pde.*.page_table_physical_addr = @truncate(@intFromPtr(page_table_addr) >> 12);
    }
}

export fn _start() align(16) linksection(".boot") callconv(.naked) noreturn {
    // enable paging
    asm volatile ("call %[init_page_dir:P]"
        :
        : [init_page_dir] "X" (&init_page_directories),
    );

    asm volatile ("call %[breakpoint:P]"
        :
        : [breakpoint] "X" (&bp),
    );

    asm volatile (
        \\ mov %eax, %cr3
        \\
        \\ mov %cr0, %eax
        \\ or $0x80000001, %eax
        \\ mov %eax, %cr0
        :
        : [page_directories] "{eax}" (&page_directories),
        : "eax"
    );

    asm volatile ("jmp higher_half_kernel");
    while (true) {}
}

export fn bp() linksection(".boot") callconv(.C) void {}

export fn higher_half_kernel() align(16) callconv(.C) noreturn {
    asm volatile ("mov %[stack_top], %esp"
        :
        : [stack_top] "{edx}" (stack_top),
    );

    root.kmain() catch |err| {
        debug.printf("Error: {s}\n", .{@errorName(err)});
    };

    while (true) {
        asm volatile ("hlt");
    }
}
