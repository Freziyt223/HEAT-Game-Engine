const std = @import("std");
const multi_execution = @import("multi_execution.zig");
const single_execution = @import("single_exectuion.zig");

pub var ThreadCount: usize = undefined;
pub var Threads: multi_execution.ExecutionQueue = undefined;
pub var MainThread: single_execution.ExecutionQueue = undefined;