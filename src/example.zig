const std = @import("std");
const Engine = @import("Engine");
const State = @import("State");

pub fn conf() void {

}

pub fn init(Init: Engine.Init) !void {
    try Engine.IO.print("Hello, {s}\n", .{"world!"});
    try Engine.IO.colourPrint("Hello, {s}\n", .{"but in red!"}, .Red);
    _ = Init;
}
pub fn deinit() void {

}

pub const update = [_]type{
    struct {
        const Self = @This();
        pub fn update(_: Self) !void {
            const Zone = Engine.ztracy.ZoneN(@src(), "Basic 60 tick");
            defer Zone.End();
        }
        pub const tick_rate: ?u64 = 60;
    },
    struct {
        const Self = @This();
        pub fn update(_: Self) !void {
            
        }
        pub const tick_rate: ?u64 = 2;
    }
};