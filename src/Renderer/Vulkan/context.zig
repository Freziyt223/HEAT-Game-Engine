// ================================================================================================
// Imports
const std = @import("std");
const zglfw = @import("zglfw");
const vulkan = @import("vulkan-zig");
const Interface = @import("Interface");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");
const Self = @This();


pub const VulkanError = error {
    NotSupportedByGLFW,
    MissingLayer
};
pub fn initContext(self: *Interface, main: type) !void {
    // ============================================================================================
    // Checking if everything is setup
    const allocator = self.vtable.allocator;
    if (!self.vtable.inited) return error.NotInitialized;
    if (!zglfw.isVulkanSupported()) return error.NotSupportedByGLFW;
    main.vkb = vulkan.BaseWrapper.load(zglfw.getInstanceProcAddress);

    if (try checkLayerSupport(allocator, main) == false) return error.MissingLayer;


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
        .enabled_layer_count = main.required_layer_names.len,
        .pp_enabled_layer_names = @ptrCast(&main.required_layer_names),
        .enabled_extension_count = @intCast(extension_names.items.len),
        .pp_enabled_extension_names = extension_names.items.ptr,
        .flags = .{.enumerate_portability_bit_khr = true}
    };
    const instance = try main.vkb.createInstance(&instanceInfo, null);
    const vki = try allocator.create(vulkan.InstanceWrapper);
    errdefer allocator.destroy(vki);
    vki.* = vulkan.InstanceWrapper.load(instance, main.vkb.dispatch.vkGetInstanceProcAddr.?);
    main.Instance = vulkan.InstanceProxy.init(instance, vki);
    errdefer main.Instance.destroyInstance(null);


    // ============================================================================================
    // This helps us get debug feedback in console
    main.debug_messenger = try main.Instance.createDebugUtilsMessengerEXT(&.{
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
    
    const physdevs = try main.Instance.enumeratePhysicalDevicesAlloc(self.vtable.allocator);
    defer allocator.free(physdevs);

    for (physdevs) |dev| {
        const properties = main.Instance.getPhysicalDeviceProperties(dev);
        const device_name = std.mem.sliceTo(&properties.device_name, 0);

        std.debug.print("=== Checking device: {s} ===\n", .{device_name});

        const propertiesList = try main.Instance.enumerateDeviceExtensionPropertiesAlloc(dev, null, allocator);
        defer allocator.free(propertiesList);

        var missing_extensions: std.ArrayList([]const u8) = .empty;
        defer missing_extensions.deinit(allocator);

        for (main.required_device_extensions) |required_ext| {
            const required_name = std.mem.sliceTo(required_ext, 0);

            var found = false;
            for (propertiesList) |available_ext| {
                const available_name = std.mem.sliceTo(&available_ext.extension_name, 0);
                if (std.mem.eql(u8, required_name, available_name)) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                try missing_extensions.append(allocator, required_name);
            }
        }

        // Додаємо усі пристрої, навіть якщо не всі розширення підтримуються
        try main.PhysicalDevices.append(allocator, .{.device = dev, .properties = properties});
        try main.PhysicalDevicesInfo.append(allocator,
            .{
                .name = try self.vtable.allocator.dupe(u8, device_name),
                .type = switch (properties.device_type) {
                    .other => Interface.deviceInfoType.device_type.other,
                    .integrated_gpu => Interface.deviceInfoType.device_type.embedded_gpu,
                    .discrete_gpu => Interface.deviceInfoType.device_type.discrete_gpu,
                    .virtual_gpu => Interface.deviceInfoType.device_type.virtual_gpu,
                    .cpu => Interface.deviceInfoType.device_type.cpu,
                    else => Interface.deviceInfoType.device_type.other
                },
                .driver_version = properties.driver_version,
            }
        );

        if (missing_extensions.items.len > 0) {
            std.debug.print("  >>> WARNING: Missing required extensions:\n", .{});
            for (missing_extensions.items) |ext| {
                std.debug.print("      - {s}\n", .{ext});
            }
        } else {
            std.debug.print("  >>> All required extensions supported\n", .{});
        }
    }
    std.debug.print("\n", .{});

    main.initedContext = true;
}


// ================================================================================================
// Wrappers
fn checkLayerSupport(allocator: std.mem.Allocator, main: type) !bool {
    const availableLayers = try main.vkb.enumerateInstanceLayerPropertiesAlloc(allocator);
    defer allocator.free(availableLayers);
    for (main.required_layer_names) |required_layer| {
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

    IO.Console.Print("[{s} {s}]: {s}\n", .{type_str, severity_str, message}) catch {return .true;};
    return .false;
}