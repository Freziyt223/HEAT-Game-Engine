const RendererType = @import("Renderer");
pub const Interface = @import("Interface");
pub const Thread = @import("Thread");

pub const Window = RendererType.Window;
pub const Renderer = RendererType.Renderer;

pub fn createWindow(
    width: c_int,
    height: c_int,
    title: [:0]const u8,
    monitor: ?*RendererType.zglfw.Monitor,
    share: ?*RendererType.zglfw.Window,
    renderer: Interface
) !Window {
    var interface = renderer;
    try interface.setup();
    var window = Window{
        .window = try RendererType.zglfw.createWindow(width, height, title, monitor, share),
        .renderer = interface,
    };
    // Must be dealocated in Interface.deinit() which is called when destroying a window
    try window.renderer.windowInit();
    return window;
}