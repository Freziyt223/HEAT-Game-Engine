const std = @import("std");
const TrackingAllocator = @import("TrackingAllocator");
pub var InternalAllocator = TrackingAllocator{.Allocator = std.heap.page_allocator, .Category = "Internal"};
pub const IO = @import("IO");