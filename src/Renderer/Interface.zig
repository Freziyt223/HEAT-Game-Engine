const std = @import("std");
const Self = @This();
const IO = @import("IO");

pub const deviceInfoType = struct {
    pub const device_type =  enum {discrete_gpu, embedded_gpu, cpu, virtual_gpu, other};
    name: []const u8, 
    type: device_type,
    driver_version: u32
};
const vtableType = struct {
    inited: bool = false,
    allocator: std.mem.Allocator = undefined,
    setup: ?*const fn(self: *Self) anyerror!void = null,
    windowInit: ?*const fn(self: *Self) anyerror!void = null,
    windowDeinit: ?*const fn(self: *Self) void = null,
    deinit: *const fn(self: *Self) void,
    context: *anyopaque = undefined,
    listDevices: ?*const fn(self: *Self) ?[]deviceInfoType
};

// Rendering device
device: *anyopaque = undefined,
vtable: vtableType,
pub fn make(vtable: vtableType) Self {
    return Self{
        .vtable = vtable
    };
}

pub fn Context(self: *Self, comptime Type: type) *Type {
    return @as(*Type, @ptrCast(self.vtable.context));
}

pub fn init(self: *Self, Allocator: std.mem.Allocator) void {
    self.vtable.allocator = Allocator;
    self.vtable.inited = true;
}
pub fn deinit(self: *Self) void {
    self.vtable.deinit(self);
}

pub fn setup(self: *Self) !void {
    if (self.vtable.setup) |func| return func(self);
}

pub fn windowInit(self: *Self) !void {
    if (self.vtable.windowInit) |func| return func(self);
}

pub fn windowDeinit(self: *Self) void {
    if (self.vtable.windowDeinit) |func| func(self);
}

pub fn listDevices(self: *Self) ?[]deviceInfoType {
    if (self.vtable.listDevices) |func| return func(self);
    return null;
}