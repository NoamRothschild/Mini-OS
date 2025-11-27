pub const PageSize = enum(u1) { @"4 KiB" = 0, @"4 MiB" = 1 };

pub const PageTableEntry = packed struct {
    present: u1 = 0, // must be 1 to map a page
    permission: enum(u1) { readonly = 0, readwrite = 1 }, // if 0, writes may not be allowed to the page referenced by this entry
    access: enum(u1) { user = 1, supervisor = 0 }, // if 0, user-mode (ring-3) accesses are not allowed to the page referenced by this entry
    page_write_through: u1, // indirectly determines the memory type used to access the page referenced by this entry
    page_cache_disable: u1, // indirectly determines the memory type used to access the page referenced by this entry
    adressed: u1 = 0, // indicates whether software has accessed the page referenced by this entry
    dirty: u1 = 0, // indicates whether software has written to the page referenced by this entry
    page_size: PageSize,
    available: u4 = 0,
    physical_addr: u20,
};

pub const PageTable = [1024]PageTableEntry;

/// A struct used by the kernel writer and not passed directly by the CPU
pub const PageDirectory = struct {
    tables: [1024]*PageTableEntry,
    physical_tables: PageTable, // should be passed to the CPU inside the cr3 reg
    physical_addr: u32,
};

comptime {
    if (@bitSizeOf(PageTableEntry) != 32)
        @compileError("PageTableEntry must be 32 bits.");
}

pub var current_directory: PageDirectory = undefined;

pub fn init() void {}
