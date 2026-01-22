const Engine = @import("Engine");
const App = @import("App");

pub fn main() !void {
    try Engine.init();
    defer Engine.deinit();
    if (@hasDecl(App, "init")) try App.init();
    defer if(@hasDecl(App, "deinit")) App.deinit();
}