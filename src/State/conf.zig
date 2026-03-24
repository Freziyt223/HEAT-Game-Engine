const std = @import("std");

pub var InitAllocator: ?std.mem.Allocator = null;
pub var JobQueueAllocator: ?std.mem.Allocator = null;