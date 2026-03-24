const std = @import("std");

pub var MainThreadId: usize = 0;
pub var NumberOfThreads: usize = 0;
// pub const JobQueue = @import("queue.zig");