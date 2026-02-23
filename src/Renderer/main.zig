pub const std = @import("std");
pub const types = @import("types");
pub const zglfw = @import("zglfw");
pub const ztracy = @import("ztracy");
pub const Interface = @import("Interface");

pub const Window = struct {
    pub const Attribute = enum(c_int) {
        focused = 0x00020001,
        iconified = 0x00020002,
        resizable = 0x00020003,
        visible = 0x00020004,
        decorated = 0x00020005,
        auto_iconify = 0x00020006,
        floating = 0x00020007,
        maximized = 0x00020008,
        center_cursor = 0x00020009,
        transparent_framebuffer = 0x0002000A,
        hovered = 0x0002000B,
        focus_on_show = 0x0002000C,
        _,

        pub fn ValueType(comptime attribute: Attribute) type {
            return switch (attribute) {
                .focused,
                .iconified,
                .resizable,
                .visible,
                .decorated,
                .auto_iconify,
                .floating,
                .maximized,
                .center_cursor,
                .transparent_framebuffer,
                .hovered,
                .focus_on_show,
                => bool,
                else => c_int,
            };
        }
    };

    pub fn destroy(self: *Window) void {
        self.renderer.windowDeinit.?(&self.renderer);
        zglfw.destroyWindow(self.window);
    }

    pub fn getAttribute(self: *const Window, comptime attrib: Attribute) Attribute.ValueType(attrib) {
        return zglfw.getWindowAttribute(self.window, attrib);
    }

    pub fn setAttribute(self: *const Window, comptime attrib: Attribute, value: Attribute.ValueType(attrib)) void {
        zglfw.setWindowAttribute(self.window, attrib, value);
    }

    pub fn getUserPointer(self: *const Window, comptime T: type) ?*T {
        return zglfw.getWindowUserPointer(self.window, T);
    }

    pub fn setUserPointer(self: *const Window, pointer: ?*anyopaque) void {
        zglfw.setWindowUserPointer(self.window, pointer);
    }

    pub fn setFramebufferSizeCallback(self: *const Window, callback: ?zglfw.FramebufferSizeFn) ?zglfw.FramebufferSizeFn {
        return zglfw.setFramebufferSizeCallback(self.window, callback);
    }

    pub fn setSizeCallback(self: *const Window, callback: ?zglfw.WindowSizeFn) ?zglfw.WindowSizeFn {
        return zglfw.setWindowSizeCallback(self.window, callback);
    }

    pub fn setPosCallback(self: *const Window, callback: ?zglfw.WindowPosFn) ?zglfw.WindowPosFn {
        return zglfw.setWindowPosCallback(self.window, callback);
    }

    pub fn setFocusCallback(self: *const Window, callback: ?zglfw.WindowFocusFn) ?zglfw.WindowFocusFn {
        return zglfw.setWindowFocusCallback(self.window, callback);
    }

    pub fn setIconifyCallback(self: *const Window, callback: ?zglfw.IconifyFn) ?zglfw.IconifyFn {
        return zglfw.setWindowIconifyCallback(self.window, callback);
    }

    pub fn setContentScaleCallback(self: *const Window, callback: ?zglfw.WindowContentScaleFn) ?zglfw.WindowContentScaleFn {
        return zglfw.setWindowContentScaleCallback(self.window, callback);
    }

    pub fn setCloseCallback(self: *const Window, callback: ?zglfw.WindowCloseFn) ?zglfw.WindowCloseFn {
        return zglfw.setWindowCloseCallback(self.window, callback);
    }

    pub fn setKeyCallback(self: *const Window, callback: ?zglfw.KeyFn) ?zglfw.KeyFn {
        return zglfw.setKeyCallback(self.window, callback);
    }

    pub fn setCharCallback(self: *const Window, callback: ?zglfw.CharFn) ?zglfw.CharFn {
        return zglfw.setCharCallback(self.window, callback);
    }

    pub fn setDropCallback(self: *const Window, callback: ?zglfw.DropFn) ?zglfw.DropFn {
        return zglfw.setDropCallback(self.window, callback);
    }

    pub fn setMouseButtonCallback(self: *const Window, callback: ?zglfw.MouseButtonFn) ?zglfw.MouseButtonFn {
        return zglfw.setMouseButtonCallback(self.window, callback);
    }

    pub fn setScrollCallback(self: *const Window, callback: ?zglfw.ScrollFn) ?zglfw.ScrollFn {
        return zglfw.setScrollCallback(self.window, callback);
    }

    pub fn setCursorPosCallback(self: *const Window, callback: ?zglfw.CursorPosFn) ?zglfw.CursorPosFn {
        return zglfw.setCursorPosCallback(self.window, callback);
    }

    pub fn setCursorEnterCallback(self: *const Window, callback: ?zglfw.CursorEnterFn) ?zglfw.CursorEnterFn {
        return zglfw.setCursorEnterCallback(self.window, callback);
    }

    pub fn getMonitor(self: *const Window) ?*zglfw.Monitor {
        return zglfw.getWindowMonitor(self.window);
    }

    pub fn setMonitor(self: *const Window, monitor: *zglfw.Monitor, xpos: c_int, ypos: c_int, width: c_int, height: c_int, refreshRate: c_int) void {
        zglfw.setWindowMonitor(self.window, monitor, xpos, ypos, width, height, refreshRate);
    }

    pub fn iconify(self: *const Window) void {
        zglfw.iconifyWindow(self.window);
    }

    pub fn restore(self: *const Window) void {
        zglfw.restoreWindow(self.window);
    }

    pub fn maximize(self: *const Window) void {
        zglfw.maximizeWindow(self.window);
    }

    pub fn show(self: *const Window) void {
        zglfw.showWindow(self.window);
    }

    pub fn hide(self: *const Window) void {
        zglfw.hideWindow(self.window);
    }

    pub fn focus(self: *const Window) void {
        zglfw.focusWindow(self.window);
    }

    pub fn requestAttention(self: *const Window) void {
        zglfw.requestWindowAttention(self.window);
    }

    pub fn getKey(self: *const Window, key: zglfw.Key) zglfw.Action {
        return zglfw.getKey(self.window, key);
    }

    pub fn getMouseButton(self: *const Window, button: zglfw.MouseButton) zglfw.Action {
        return zglfw.getMouseButton(self.window, button);
    }

    pub fn setSizeLimits(self: *const Window, min_width: c_int, min_height: c_int, max_width: c_int, max_height: c_int) void {
        zglfw.setWindowSizeLimits(self.window, min_width, min_height, max_width, max_height);
    }

    pub fn setAspectRatio(self: *const Window, numer: c_int, denom: c_int) void {
        zglfw.setWindowAspectRatio(self.window, numer, denom);
    }

    pub fn getOpacity(self: *const Window) f32 {
        return zglfw.getWindowOpacity(self.window);
    }

    pub fn setOpacity(self: *const Window, opacity: f32) void {
        zglfw.setWindowOpacity(self.window, opacity);
    }

    pub fn setSize(self: *const Window, width: c_int, height: c_int) void {
        zglfw.setWindowSize(self.window, width, height);
    }

    pub fn setPos(self: *const Window, xpos: c_int, ypos: c_int) void {
        zglfw.setWindowPos(self.window, xpos, ypos);
    }

    pub fn setTitle(self: *const Window, title: [:0]const u8) void {
        zglfw.setWindowTitle(self.window, title);
    }

    pub fn setIcon(self: *const Window, count: c_int, images: []const zglfw.Image) void {
        zglfw.setWindowIcon(self.window, count, images);
    }

    pub fn shouldClose(self: *const Window) bool {
        return zglfw.windowShouldClose(self.window);
    }

    pub fn setShouldClose(self: *const Window, value: bool) void {
        zglfw.setWindowShouldClose(self.window, value);
    }

    pub fn getClipboardString(self: *const Window, allocator: std.mem.Allocator) ![]u8 {
        return zglfw.getClipboardString(self.window, allocator);
    }

    pub fn setClipboardString(self: *const Window, string: [:0]const u8) void {
        zglfw.setClipboardString(self.window, string);
    }

    pub fn setCursor(self: *const Window, cursor: ?*zglfw.Cursor) void {
        zglfw.setCursor(self.window, cursor);
    }

    pub fn getInputMode(self: *const Window, comptime mode: zglfw.InputMode) zglfw.InputMode.ValueType(mode) {
        return zglfw.getInputMode(self.window, mode);
    }

    pub fn setInputMode(self: *const Window, comptime mode: zglfw.InputMode, value: zglfw.InputMode.ValueType(mode)) zglfw.Error!void {
        return zglfw.setInputMode(self.window, mode, value);
    }

    pub fn setInputModeUntyped(self: *const Window, mode: zglfw.InputMode, value: anytype) zglfw.Error!void {
        return zglfw.setInputModeUntyped(self.window, mode, value);
    }

    pub fn swapBuffers(self: *const Window) void {
        zglfw.swapBuffers(self.window);
    }

    pub fn getCursorPos(self: *const Window) [2]f64 {
        var xpos: f64 = 0.0;
        var ypos: f64 = 0.0;
        zglfw.getCursorPos(self.window, &xpos, &ypos);
        return .{ xpos, ypos };
    }

    pub fn getContentScale(self: *const Window) [2]f32 {
        var xscale: f32 = 0.0;
        var yscale: f32 = 0.0;
        zglfw.getWindowContentScale(self.window, &xscale, &yscale);
        return .{ xscale, yscale };
    }

    pub fn getFrameSize(self: *const Window) [4]c_int {
        var left: c_int = 0;
        var top: c_int = 0;
        var right: c_int = 0;
        var bottom: c_int = 0;
        zglfw.getWindowFrameSize(self.window, &left, &top, &right, &bottom);
        return .{ left, top, right, bottom };
    }

    pub fn getFramebufferSize(self: *const Window) [2]c_int {
        var width: c_int = 0;
        var height: c_int = 0;
        zglfw.getFramebufferSize(self.window, &width, &height);
        return .{ width, height };
    }

    pub fn getSize(self: *const Window) [2]c_int {
        var width: c_int = 0;
        var height: c_int = 0;
        zglfw.getWindowSize(self.window, &width, &height);
        return .{ width, height };
    }

    pub fn getPos(self: *const Window) [2]c_int {
        var xpos: c_int = 0;
        var ypos: c_int = 0;
        zglfw.getWindowPos(self.window, &xpos, &ypos);
        return .{ xpos, ypos };
    }

    window: *zglfw.Window,
    renderer: Interface,
};

pub fn Renderer(
    renderer: enum {OpenGL, Vulkan, none}, 
) Interface {
    switch (renderer) {
        .OpenGL => {
            return @import("OpenGL/main.zig").interface();
        },
        .Vulkan => {
            return @import("OpenGL/main.zig").interface();
        },
        .none => {
            return @import("OpenGL/main.zig").interface();
        },
    }
}