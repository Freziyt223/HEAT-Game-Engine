// ================================================================================================
// Imports
const std = @import("std");
const zglfw = @import("zglfw");
const Interface = @import("Interface");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");


// ================================================================================================
// Top-level fields for opengl


// ================================================================================================
// Config
var inited: bool = false;
var initedContext: bool = false;
const Context = struct {};

pub const InterfaceError = error{
    NotInitialized
};


// ================================================================================================
/// Use this to get renderer interface
pub fn interface() Interface {
    return Interface{
        .setup = &setupInterface,
        .windowInit = &windowInit,
        .windowDeinit = &windowDeinit,
        .deinit = &deinit
    };
}

pub fn deinit(self: *Interface) void {
    _ = self;
}


// ================================================================================================
// Internal vulkan functions
fn setupInterface(self: *Interface) !void {
    zglfw.windowHint(.client_api, .no_api);
    zglfw.windowHint(.resizable, false);
    if (!initedContext) return initContext(self);
}

pub fn windowInit(self: *Interface) !void {
    self.context = try self.allocator.create(Context);
}

pub fn windowDeinit(self: *Interface) void {
    self.allocator.destroy(self.Context(Context));
}

fn initContext(_: *Interface) !void {

}