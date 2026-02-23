// ================================================================================================
// Imports
const std = @import("std");
const zglfw = @import("zglfw");
const vulkan = @import("vulkan-zig");
const Interface = @import("Interface");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");


// ================================================================================================
// Top-level fields for vulkan
const required_layer_names = [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};
const required_device_extensions = [_][*:0]const u8{vulkan.extensions.khr_swapchain.name};


// ================================================================================================
// Config
var initedContext: bool = false;
const Context = struct {};


// ================================================================================================
// Shared vulkan fields
var vkb: vulkan.BaseWrapper = undefined;
var Instance: vulkan.InstanceProxy = undefined;
var debug_messenger: vulkan.DebugUtilsMessengerEXT = undefined;

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

pub fn deinit(self: *const Interface) void {
    const allocator = self.allocator;
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
    if (!initedContext) return initContext(self);
}

pub const VulkanError = error {
    NotSupportedByGLFW,
    MissingLayer
};
fn initContext(self: *Interface) !void {
    // ============================================================================================
    // Checking if everything is setup
    const allocator = self.allocator;
    if (!self.inited) return error.NotInitialized;
    if (!zglfw.isVulkanSupported()) return error.NotSupportedByGLFW;
    vkb = vulkan.BaseWrapper.load(zglfw.getInstanceProcAddress);

    if (try checkLayerSupport(allocator) == false) return error.MissingLayer;


    // ============================================================================================
    // Getting vulkan extensions
    var extension_names: std.ArrayList([*:0]const u8) = .empty;
    defer extension_names.deinit(allocator);
    try extension_names.append(allocator, vulkan.extensions.ext_debug_utils.name);
    try extension_names.append(allocator, vulkan.extensions.khr_portability_enumeration.name);
    try extension_names.append(allocator, vulkan.extensions.khr_get_physical_device_properties_2.name);

    const glfw_exts = try zglfw.getRequiredInstanceExtensions();
    try extension_names.appendSlice(allocator, glfw_exts);


    // ============================================================================================
    // Setting up an Instance
    const AppInfo = vulkan.ApplicationInfo{
        .p_application_name = "Heat Engine",
        .application_version = @bitCast(vulkan.makeApiVersion(0, 0, 0,0)),
        .p_engine_name = "Heat Engine",
        .engine_version = @bitCast(vulkan.makeApiVersion(0, 0, 0, 0)),
        .api_version = @bitCast(vulkan.API_VERSION_1_2),
    };
    const instanceInfo = vulkan.InstanceCreateInfo{
        .p_application_info = &AppInfo,
        .enabled_layer_count = required_layer_names.len,
        .pp_enabled_layer_names = @ptrCast(&required_layer_names),
        .enabled_extension_count = @intCast(extension_names.items.len),
        .pp_enabled_extension_names = extension_names.items.ptr,
        .flags = .{.enumerate_portability_bit_khr = true}
    };
    const instance = try vkb.createInstance(&instanceInfo, null);
    const vki = try allocator.create(vulkan.InstanceWrapper);
    errdefer allocator.destroy(vki);
    vki.* = vulkan.InstanceWrapper.load(instance, vkb.dispatch.vkGetInstanceProcAddr.?);
    Instance = vulkan.InstanceProxy.init(instance, vki);
    errdefer Instance.destroyInstance(null);


    // ============================================================================================
    // This helps us get debug feedback in console
    debug_messenger = try Instance.createDebugUtilsMessengerEXT(&.{
        .message_severity = .{
            //.verbose_bit_ext = true,
            //.info_bit_ext = true,
            .warning_bit_ext = true,
            .error_bit_ext = true,
        },
        .message_type = .{
            .general_bit_ext = true,
            .validation_bit_ext = true,
            .performance_bit_ext = true,
        },
        .pfn_user_callback = &debugUtilsMessengerCallback,
        .p_user_data = null,
    }, null);
}

/// Create window specific context like Surface, callbacks etc.
fn windowInit(self: *Interface) !void {
    
    self.context = try self.allocator.create(Context);
}

fn windowDeinit(self: *Interface) void {
    self.allocator.destroy(self.Context(Context));
}


// ================================================================================================
// Wrappers
fn checkLayerSupport(allocator: std.mem.Allocator) !bool {
    const availableLayers = try vkb.enumerateInstanceLayerPropertiesAlloc(allocator);
    defer allocator.free(availableLayers);
    for (required_layer_names) |required_layer| {
        for (availableLayers) |layer| {
            if (std.mem.eql(u8, std.mem.span(required_layer), std.mem.sliceTo(&layer.layer_name, 0))) break;
        } else {
            return false;
        }
    }
    return true;
}

fn debugUtilsMessengerCallback(
    severity: vulkan.DebugUtilsMessageSeverityFlagsEXT,
    msg_type: vulkan.DebugUtilsMessageTypeFlagsEXT,
    callback_data: ?*const vulkan.DebugUtilsMessengerCallbackDataEXT,
    _: ?*anyopaque
) callconv(.c) vulkan.Bool32 {
    const severity_str = if (severity.verbose_bit_ext) "verbose" else if (severity.warning_bit_ext) "WARNING" else if (severity.error_bit_ext) "ERROR" else "unknown";
    const type_str = if (msg_type.general_bit_ext) "General" else if (msg_type.validation_bit_ext) "Validation" else if (msg_type.performance_bit_ext) "Performance" else if (msg_type.device_address_binding_bit_ext) "Device addr" else "unknown";
    const message: [*c]const u8 = if (callback_data) |cb_data| cb_data.p_message else "NO MESSAGE!";

    IO.Console.Print("[{s} {s}]: {s}\n", .{type_str, severity_str, message});
    return .false;
}