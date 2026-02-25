// ================================================================================================
// Imports
const std = @import("std");
const zglfw = @import("zglfw");
const vulkan = @import("vulkan-zig");
const Interface = @import("Interface");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");
const Self = @This();

const Context = struct {};

/// Create window specific context like Surface, callbacks etc.
pub fn windowInit(self: *Interface) !void {
    const allocator = self.vtable.allocator;
    self.vtable.context = try self.vtable.allocator.create(Context);
    _ = allocator;
}

pub fn windowDeinit(self: *Interface) void {
    self.vtable.allocator.destroy(self.Context(Context));
}
