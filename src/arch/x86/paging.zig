pub const PageSize = enum(u1) { @"4 KiB" = 0, @"4 MiB" = 1 };

pub const PageDirectoryEntry = packed struct {
    present: u1 = 0, // must be 1 to map a page
    permission: enum(u1) { readonly = 0, readwrite = 1 }, // if 0, writes may not be allowed to the page referenced by this entry
    access: enum(u1) { user = 1, supervisor = 0 }, // if 0, user-mode (ring-3) accesses are not allowed to the page referenced by this entry
    page_write_through: u1, // indirectly determines the memory type used to access the page referenced by this entry
    page_cache_disable: u1, // indirectly determines the memory type used to access the page referenced by this entry
    adressed: u1 = 0, // indicates whether software has accessed the page referenced by this entry
    dirty: u1 = 0, // indicates whether software has written to the page referenced by this entry
    page_size: PageSize,
    available: u4 = 0,
    page_table_physical_addr: u20,
};

pub const PageTableEntry = packed struct {
    present: u1 = 0, // must be 1 to map a page
    permission: enum(u1) { readonly = 0, readwrite = 1 }, // if 0, writes may not be allowed to the page referenced by this entry
    access: enum(u1) { user = 1, supervisor = 0 }, // if 0, user-mode (ring-3) accesses are not allowed to the page referenced by this entry
    page_write_through: u1, // indirectly determines the memory type used to access the page referenced by this entry
    page_cache_disable: u1, // indirectly determines the memory type used to access the page referenced by this entry
    adressed: u1 = 0, // indicates whether software has accessed the page referenced by this entry
    dirty: u1 = 0, // indicates whether software has written to the page referenced by this entry
    page_attribute: u1,
    global: u1,
    available: u3 = 0,
    physical_addr: u20,
};

comptime {
    if (@bitSizeOf(PageTableEntry) != 32)
        @compileError("PageTableEntry must be 32 bits.");
}

pub const kernel_table_page: PageTableEntry = .{
    .present = 1,
    .permission = .readwrite,
    .access = .supervisor,
    .page_write_through = 0,
    .page_cache_disable = 0,
    .page_attribute = 0,
    .global = 0,
    .physical_addr = 0,
};

pub const kernel_directory_page: PageDirectoryEntry = .{
    .present = 1,
    .permission = .readwrite,
    .access = .supervisor,
    .page_write_through = 0,
    .page_cache_disable = 0,
    .page_size = .@"4 KiB",
    .page_table_physical_addr = 0,
};

pub const non_present_directory_page: PageDirectoryEntry = @bitCast(@as(u32, 0));

pub fn init() void {}
