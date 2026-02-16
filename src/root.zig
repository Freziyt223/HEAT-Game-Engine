const std = @import("std");
pub const TrackingAllocator = @import("TrackingAllocator");
pub var InternalAllocator: TrackingAllocator = undefined;
pub var QueueAllocator: TrackingAllocator = undefined;
pub const IO = @import("IO");
pub const ztracy = @import("ztracy");
pub const Thread = @import("Thread");
pub const types = @import("types");
pub const Renderer = @import("Renderer");

pub const Init = struct {
    Args: std.process.ArgIterator,
    Allocator: std.mem.Allocator
};