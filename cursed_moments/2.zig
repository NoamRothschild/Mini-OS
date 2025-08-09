fn vgaColor(comptime color: u8, comptime char: u8) u16 {
    return asm volatile (
        \\ mov %[char], %%al
        \\ mov %[color], %%ah
        : [ret] "={ax}" (-> u16),
        : [color] "i" (color),
          [char] "i" (char),
    );
}
