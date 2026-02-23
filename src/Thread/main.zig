const std = @import("std");
const multi_execution = @import("multi_execution.zig");

pub var ThreadCount: usize = undefined;
pub var Threads: multi_execution.ExecutionQueue = undefined;
pub var MainThread: multi_execution.ExecutionQueue = undefined;