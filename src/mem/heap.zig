const std = @import("std");

// kernel heap will be 4 MiB long
export var kernel_heap: [4096 * 1024]u8 linksection(".heap") = undefined;

var kernel_fba = std.heap.FixedBufferAllocator.init(&kernel_heap);
pub const kallocator = kernel_fba.allocator();
