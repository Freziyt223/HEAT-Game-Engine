const std = @import("std");
const Self = @This();

inited: bool = false,
allocator: std.mem.Allocator = undefined,
setup: ?*const fn(self: *Self) anyerror!void = null,
windowInit: ?*const fn(self: *Self) anyerror!void = null,
windowDeinit: ?*const fn(self: *Self) void = null,
deinit: *const fn(self: *Self) void,

context: *anyopaque = undefined,
pub fn Context(self: *Self, comptime Type: type) *Type {
    return @as(*Type, @ptrCast(self.context));
}

pub fn init(self: *Self, Allocator: std.mem.Allocator) void {
    self.allocator = Allocator;
    self.inited = true;
}