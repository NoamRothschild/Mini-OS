const kilobyte: comptime_int = 1024;
const megabyte: comptime_int = kilobyte * kilobyte;

pub const stack_size = 16 * kilobyte;
pub const syscall_number = 0x90; // 144 :)
