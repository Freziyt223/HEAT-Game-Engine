pub const std = @import("std");
pub const types = @import("types");
pub const zglfw = @import("zglfw");
pub const ztracy = @import("ztracy");
pub const Interface = @import("Interface");
const buildOptions = @import("buildOptions");
const Thread = @import("Thread");

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

    fn getHandle(self: *const Window) *zglfw.Window {
        return self.window orelse @panic("Window handle is null: the window might have been destroyed or not initialized.");
    }

    pub fn destroy(self: *Window) void {
        const w = self.getHandle();
        self.renderer.windowDeinit();
        Thread.MainThread.submit(zglfw.destroyWindow, .{w});
        self.window = null;
    }

    pub fn getAttribute(self: *const Window, comptime attrib: Attribute) Attribute.ValueType(attrib) {
        return Thread.MainThread.submitWithReturn(zglfw.getWindowAttribute, .{ self.getHandle(), attrib });
    }

    pub fn setAttribute(self: *const Window, comptime attrib: Attribute, value: Attribute.ValueType(attrib)) void {
        Thread.MainThread.submit(zglfw.setWindowAttribute, .{ self.getHandle(), attrib, value });
    }

    pub fn getUserPointer(self: *const Window, comptime T: type) ?*T {
        return Thread.MainThread.submitWithReturn(
            zglfw.getWindowUserPointer,
            .{ self.getHandle(), T }
        );
    }

    pub fn setUserPointer(self: *const Window, pointer: ?*anyopaque) void {
        Thread.MainThread.submit(
            zglfw.setWindowUserPointer,
            .{ self.getHandle(), pointer }
        );
    }

    pub fn setFramebufferSizeCallback(self: *const Window, callback: ?zglfw.FramebufferSizeFn) ?zglfw.FramebufferSizeFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setFramebufferSizeCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setSizeCallback(self: *const Window, callback: ?zglfw.WindowSizeFn) ?zglfw.WindowSizeFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowSizeCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setPosCallback(self: *const Window, callback: ?zglfw.WindowPosFn) ?zglfw.WindowPosFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowPosCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setFocusCallback(self: *const Window, callback: ?zglfw.WindowFocusFn) ?zglfw.WindowFocusFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowFocusCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setIconifyCallback(self: *const Window, callback: ?zglfw.IconifyFn) ?zglfw.IconifyFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowIconifyCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setContentScaleCallback(self: *const Window, callback: ?zglfw.WindowContentScaleFn) ?zglfw.WindowContentScaleFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowContentScaleCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setCloseCallback(self: *const Window, callback: ?zglfw.WindowCloseFn) ?zglfw.WindowCloseFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setWindowCloseCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setKeyCallback(self: *const Window, callback: ?zglfw.KeyFn) ?zglfw.KeyFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setKeyCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setCharCallback(self: *const Window, callback: ?zglfw.CharFn) ?zglfw.CharFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setCharCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setDropCallback(self: *const Window, callback: ?zglfw.DropFn) ?zglfw.DropFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setDropCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setMouseButtonCallback(self: *const Window, callback: ?zglfw.MouseButtonFn) ?zglfw.MouseButtonFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setMouseButtonCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setScrollCallback(self: *const Window, callback: ?zglfw.ScrollFn) ?zglfw.ScrollFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setScrollCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setCursorPosCallback(self: *const Window, callback: ?zglfw.CursorPosFn) ?zglfw.CursorPosFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setCursorPosCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn setCursorEnterCallback(self: *const Window, callback: ?zglfw.CursorEnterFn) ?zglfw.CursorEnterFn {
        return Thread.MainThread.submitWithReturn(
            zglfw.setCursorEnterCallback,
            .{ self.getHandle(), callback }
        );
    }

    pub fn getMonitor(self: *const Window) ?*zglfw.Monitor {
        return Thread.MainThread.submitWithReturn(
            zglfw.getWindowMonitor,
            .{ self.getHandle() }
        );
    }

    pub fn setMonitor(self: *const Window, monitor: *zglfw.Monitor, xpos: c_int, ypos: c_int, width: c_int, height: c_int, refreshRate: c_int) void {
        Thread.MainThread.submit(
            zglfw.setWindowMonitor,
            .{ self.getHandle(), monitor, xpos, ypos, width, height, refreshRate }
        );
    }

    pub fn iconify(self: *const Window) void {
        Thread.MainThread.submit(zglfw.iconifyWindow, .{ self.getHandle() });
    }

    pub fn restore(self: *const Window) void {
        Thread.MainThread.submit(zglfw.restoreWindow, .{ self.getHandle() });
    }

    pub fn maximize(self: *const Window) void {
        Thread.MainThread.submit(zglfw.maximizeWindow, .{ self.getHandle() });
    }

    pub fn show(self: *const Window) void {
        Thread.MainThread.submit(zglfw.showWindow, .{ self.getHandle() });
    }

    pub fn hide(self: *const Window) void {
        Thread.MainThread.submit(zglfw.hideWindow, .{ self.getHandle() });
    }

    pub fn focus(self: *const Window) void {
        Thread.MainThread.submit(zglfw.focusWindow, .{ self.getHandle() });
    }

    pub fn requestAttention(self: *const Window) void {
        Thread.MainThread.submit(zglfw.requestWindowAttention, .{ self.getHandle() });
    }

    pub fn getKey(self: *const Window, key: zglfw.Key) zglfw.Action {
        return self.getHandle().getKey(key);
    }

    pub fn getMouseButton(self: *const Window, button: zglfw.MouseButton) zglfw.Action {
        return self.getMouseButton(button);
    }

    pub fn setSizeLimits(self: *const Window, min_width: c_int, min_height: c_int, max_width: c_int, max_height: c_int) void {
        Thread.MainThread.submit(
            zglfw.setWindowSizeLimits,
            .{ self.getHandle(), min_width, min_height, max_width, max_height }
        );
    }

    pub fn setAspectRatio(self: *const Window, numer: c_int, denom: c_int) void {
        Thread.MainThread.submit(
            zglfw.setWindowAspectRatio,
            .{ self.getHandle(), numer, denom }
        );
    }

    pub fn getOpacity(self: *const Window) f32 {
        return Thread.MainThread.submitWithReturn(
            zglfw.getWindowOpacity,
            .{ self.getHandle() }
        );
    }

    pub fn setOpacity(self: *const Window, opacity: f32) void {
        Thread.MainThread.submit(
            zglfw.setWindowOpacity,
            .{ self.getHandle(), opacity }
        );
    }

    pub fn setSize(self: *const Window, width: c_int, height: c_int) void {
        Thread.MainThread.submit(
            zglfw.setWindowSize,
            .{ self.getHandle(), width, height }
        );
    }

    pub fn setPos(self: *const Window, xpos: c_int, ypos: c_int) void {
        Thread.MainThread.submit(
            zglfw.setWindowPos,
            .{ self.getHandle(), xpos, ypos }
        );
    }

    pub fn setTitle(self: *const Window, title: [:0]const u8) void {
        Thread.MainThread.submit(
            zglfw.setWindowTitle,
            .{ self.getHandle(), title }
        );
    }

    pub fn setIcon(self: *const Window, count: c_int, images: []const zglfw.Image) void {
        Thread.MainThread.submit(
            zglfw.setWindowIcon,
            .{ self.getHandle(), count, images }
        );
    }

    pub fn shouldClose(self: *const Window) bool {
        return self.getHandle().shouldClose();
    }

    pub fn setShouldClose(self: *const Window, value: bool) void {
        Thread.MainThread.submit(
            zglfw.setWindowShouldClose,
            .{ self.getHandle(), value }
        );
    }

    pub fn getClipboardString(self: *const Window, allocator: std.mem.Allocator) ![]u8 {
        return try Thread.MainThread.submitWithReturn(
            zglfw.getClipboardString,
            .{ self.getHandle(), allocator }
        );
    }

    pub fn setClipboardString(self: *const Window, string: [:0]const u8) void {
        Thread.MainThread.submit(
            zglfw.setClipboardString,
            .{ self.getHandle(), string }
        );
    }

    pub fn setCursor(self: *const Window, cursor: ?*zglfw.Cursor) void {
        Thread.MainThread.submit(
            zglfw.setCursor,
            .{ self.getHandle(), cursor }
        );
    }

    pub fn getInputMode(self: *const Window, comptime mode: zglfw.InputMode) zglfw.InputMode.ValueType(mode) {
        return Thread.MainThread.submitWithReturn(
            zglfw.getInputMode,
            .{ self.getHandle(), mode }
        );
    }

    pub fn setInputMode(self: *const Window, comptime mode: zglfw.InputMode, value: zglfw.InputMode.ValueType(mode)) !void {
        return try Thread.MainThread.submitWithReturn(
            zglfw.setInputMode,
            .{ self.getHandle(), mode, value }
        );
    }

    pub fn setInputModeUntyped(self: *const Window, mode: zglfw.InputMode, value: anytype) !void {
        return try Thread.MainThread.submitWithReturn(
            zglfw.setInputModeUntyped,
            .{ self.getHandle(), mode, value }
        );
    }

    pub fn swapBuffers(self: *const Window) void {
        Thread.MainThread.submit(
            zglfw.swapBuffers,
            .{ self.getHandle() }
        );
    }

    pub fn getCursorPos(self: *const Window) [2]f64 {
        return self.getHandle().getCursorPos();
    }

    pub fn getContentScale(self: *const Window) [2]f32 {
        return self.getHandle().getContentScale();
    }

    pub fn getFrameSize(self: *const Window) [4]c_int {
        return self.getHandle().getFrameSize();
    }

    pub fn getFramebufferSize(self: *const Window) [2]c_int {
        return self.getHandle().getFramebufferSize();
    }

    pub fn getSize(self: *const Window) [2]c_int {
        return self.getHandle().getSize();
    }

    pub fn getPos(self: *const Window) [2]c_int {
        return self.getHandle().getPos();
    }

    window: ?*zglfw.Window,
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
            if (buildOptions.enable_vulkan) return @import("Vulkan/main.zig").interface() else @panic("Vulkan was not included when building the application. Paramether enable_vulkan is off!\n");
        },
        .none => {
            return @import("none.zig").interface();
        },
    }
}