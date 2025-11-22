// https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.pdf
// page 114

/// the struct of a 4kb PDE page table
const PageDirectoryEntry = packed struct {
    present: u1, // must be 1 to reference a page table
    permission: enum(u1) { read = 0, write = 1 }, // if 0, writes may not be allowed to the 4-KByte region controlled by this entry
    access: enum(u1) { user = 1, supervisor = 0 }, // if 0, user-mode (ring-3) accesses are not allowed to the 4-KByte region controlled by this entry
    page_write_through: u1, // indirectly determines the memory type used to access the 4-KByte page referenced by this entry
    page_cache_disable: u1, // indirectly determines the memory type used to access the 4-KByte page referenced by this entry
    adressed: u1, // indicates whether this entry has been used for linear-address translation
    _: u1,
    page_size: u1 = 0, // ignored for CR4.PSE = 0 ; no 4Mb pages
    __: u4,
    physical_addr: u20, // Physical address of 4-KByte aligned page table referenced by this entry
};

/// the struct of a 4kb PTE page table
const PageTableEntry = packed struct {
    present: u1, // must be 1 to map a 4kb page
    permission: enum(u1) { read = 0, write = 1 }, // if 0, writes may not be allowed to the 4-KByte page referenced by this entry
    access: enum(u1) { user = 1, supervisor = 0 }, // if 0, user-mode (ring-3) accesses are not allowed to the 4-KByte page referenced by this entry
    page_write_through: u1, // indirectly determines the memory type used to access the 4-KByte page referenced by this entry
    page_cache_disable: u1, // indirectly determines the memory type used to access the 4-KByte page referenced by this entry
    adressed: u1, // indicates whether software has accessed the 4-KByte page referenced by this entry
    dirty: u1, // indicates whether software has written to the 4-KByte page referenced by this entry
    pat: u1, // if the PAT is supported (debug.getFeatures().pat == 1), indirectly determines the memory type used to access the 4-KByte page referenced by this entry, otherwise, must be 0
    global: u1, // if CR4.PGE = 1, determines whether the translation is global, ignored otherwise
    _: u3,
    physical_addr: u20, // Physical address of the 4-KByte page referenced by this entry
};

comptime {
    const pte_size = @bitSizeOf(PageTableEntry);
    if (pte_size != 32)
        @compileError("pte table entry must be 32 bits!");

    // const pde_size = @bitSizeOf(PageDirectoryEntry);
    // if (pde_size != 32)
    //     @compileError("pde directory entry must be 32 bits!");
}

var page_dir_entries: [1024]PageDirectoryEntry = undefined;

pub fn init() void {
    // asm volatile (
    //     \\ mov %[page_dir], %eax
    //     \\ mov %eax, %cr3
    //     \\
    //     \\ mov %cr0, %eax
    //     \\ or $0x80000001, %eax
    //     \\ mov %eax, %cr0
    //     :
    //     : [page_dir] "{eax}" (&page_dir_entries),
    //     : "eax"
    // );
}
