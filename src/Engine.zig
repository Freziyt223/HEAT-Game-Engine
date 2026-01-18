//!
//! 
// ----------------------------------------------------------------------------------
// Imports section and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
pub const TrackingAllocator = @import("Core/TrackingAllocator.zig");
pub var InternalAllocator = TrackingAllocator{.InternalAllocator = std.heap.page_allocator, .Category = "Internal"};
pub const IO = @import("Core/IO.zig");
pub const Colour = @import("Core/Colour.zig");
pub const Platform = @import("Platform");
pub const Self = @This();


// ----------------------------------------------------------------------------------
// Engine entrypoints
// ----------------------------------------------------------------------------------
pub fn run() !void {
    try Platform.init(&InternalAllocator);
    try IO.init(&InternalAllocator);
    try IO.Console.Print("Hello, {s}", .{"world!"});
}


// ----------------------------------------------------------------------------------
// User functions
// ----------------------------------------------------------------------------------
pub var init: ?*fn(args: std.process.ArgIterator) anyerror!void = null;
pub var deinit: ?*fn() void = null;
pub var update: ?*fn() anyerror!void = null;
pub var draw: ?*fn() anyerror!void = null;