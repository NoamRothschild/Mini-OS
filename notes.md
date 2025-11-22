# PAGING

-- setting up 32-bit paging
CR0.PG = 1
CR4.PAE = 0 -- no PAE
IA32_EFER.LME = 0 -- the proccesor should ensure this
CR4.PGE = 1 -- enable global paging

-- paging modifiers
CR4.PSE = 0 -- only 4kb pages

-- is PAT enabled?
If CPUID.01H:EDX.PAT [bit 16] = 1, the 8-entry page-attribute table (PAT) is supported. When the PAT is
supported, three bits in certain paging-structure entries select a memory type (used to determine type of
caching used) from the PAT

A 4-KByte naturally aligned page directory is located at the physical address specified in bits 31:12 of CR

 page directory comprises 1024 32-bit entries (PDEs). A PDE is selected using the physical address
defined as follows:
— Bits 39:32 are all 0.
— Bits 31:12 are from CR3
— Bits 11:2 are bits 31:22 of the linear address.
— Bits 1:0 are 0


PDPTE registers
138
