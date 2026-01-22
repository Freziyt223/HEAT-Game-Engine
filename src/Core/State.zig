//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
const Platform = @import("Platform");
const TrackingAllocator = @import("TrackingAllocator.zig");
var Allocator: *TrackingAllocator = undefined;

var State: struct {
    windows: std.ArrayList(u8),
    Running: bool = false,

} = .{.windows = .empty};
var LastError: c_int = 0;


// ----------------------------------------------------------------------------------
// Functions to interact with state
// ----------------------------------------------------------------------------------
pub fn init(allocator: *TrackingAllocator) !void {
    Allocator = allocator;
}

pub fn Running() bool {
    return State.Running;
}

pub fn setRunning(state: bool) void {
    State.Running = state;
}

pub fn getLastError() c_int {
    return LastError;
}

pub fn setLastError(state: c_int) void {
    LastError = state;
}