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
pub const State = @import("Core/State.zig");
pub const Self = @This();


// ----------------------------------------------------------------------------------
// Engine entrypoints
// ----------------------------------------------------------------------------------
// ... needs to be reworked

pub fn init() !void {
    try Platform.init(&InternalAllocator);
    try IO.init(&InternalAllocator);
    try State.init(&InternalAllocator);
}
pub fn deinit() void {

}

pub fn update() !void {

}
pub fn draw() !void {

}

// ----------------------------------------------------------------------------------
// User functions
// ----------------------------------------------------------------------------------
// ...