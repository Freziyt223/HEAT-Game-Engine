const Engine = @import("Engine");

pub fn init() !void {
    try Engine.IO.Console.Print("Hello, {s}\n", .{"world!"});
    try Engine.IO.Console.Colour.Print("Hello, {s}\n", .{"but in red!"}, .{.indexes = .{255, 0, 0, 0}});
}