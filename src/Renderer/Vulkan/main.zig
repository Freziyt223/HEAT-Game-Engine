// ================================================================================================
// Imports
const std = @import("std");
const zglfw = @import("zglfw");
const vulkan = @import("vulkan-zig");
const Interface = @import("Interface");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");
const Self = @This();
const context = @import("context.zig");
const windowSpecific = @import("windowSpecific.zig");


// ================================================================================================
// Top-level fields for vulkan
pub const required_layer_names= [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};
pub const required_device_extensions = [_][*:0]const u8{vulkan.extensions.khr_swapchain.name};


// ================================================================================================
// Config
pub var initedContext: bool = false;


// ================================================================================================
// Shared vulkan fields
pub var vkb: vulkan.BaseWrapper = undefined;
pub var Instance: vulkan.InstanceProxy = undefined;
pub var debug_messenger: vulkan.DebugUtilsMessengerEXT = undefined;

// var PhysicalDevicesInfo: std.ArrayList() = .empty;
pub var PhysicalDevices: std.ArrayList(struct {device: vulkan.PhysicalDevice, properties: vulkan.PhysicalDeviceProperties}) = .empty;
pub var PhysicalDevicesInfo: std.ArrayList(Interface.deviceInfoType) = .empty;
pub const InterfaceError = error{
    NotInitialized
};


// ================================================================================================
/// Use this to get renderer interface
pub fn interface() Interface {
    return Interface.make(.{
        .setup = @ptrCast(&setupInterface),
        .windowInit = @ptrCast(&windowSpecific.windowInit),
        .windowDeinit = @ptrCast(&windowSpecific.windowDeinit),
        .deinit = @ptrCast(&deinit),
        .listDevices = @ptrCast(&listDevices)
    });
}

pub fn deinit(self: *const Interface) void {
    const allocator = self.vtable.allocator;
    for (PhysicalDevicesInfo.items) |info| {
        allocator.free(info.name);
    }
    PhysicalDevicesInfo.deinit(allocator);
    PhysicalDevices.deinit(allocator);
    Instance.destroyDebugUtilsMessengerEXT(debug_messenger, null);
    Instance.destroyInstance(null);

    allocator.destroy(Instance.wrapper);
}


// ================================================================================================
// Internal vulkan functions
/// set glfw hints and create global context like Instance, Device etc.
fn setupInterface(self: *Interface) !void {
    zglfw.windowHint(.client_api, .no_api);
    zglfw.windowHint(.resizable, false);
    if (initedContext == false) return context.initContext(self, Self);
}

fn listDevices(_: *Interface) ?[]Interface.deviceInfoType {
    if (PhysicalDevicesInfo.items.len == 0) return null;
    return PhysicalDevicesInfo.items;
}