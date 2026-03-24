const std = @import("std");
const State = @import("State");
var Mutex = std.Thread.Mutex{};

pub const Colour = extern union {
    // Values from Hex are represented as bytes and u32 is separated into
    // two halfs called endians, where little one to the right(if you write from left to right)
    // So in memory endians are swapped, so hex 0xFFEEDD__(red) will be 0xDD__FFEE
    // So that's why we have them in like this
    rgba: extern struct {b: u8, _: u8, r: u8, g: u8},
    Hex: u32,
    pub const Red: Colour = .{.Hex = 0xFF0000};
    pub const Blue: Colour = .{.Hex = 0x00FF00};
    pub const Green: Colour = .{.Hex = 0x0000FF};
    pub const White: Colour = .{.Hex = 0xFFFFFF};
    pub const Black: Colour = .{.Hex = 0x000000};
};


pub fn print(comptime fmt: []const u8, args: anytype) !void {
    Mutex.lock();
    defer Mutex.unlock();
    var buf: [2048]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(buf[0..buf.len]);
    try stdout.interface.print(fmt, args);
    try stdout.interface.flush();
}

pub fn read(buf: []u8) !usize {
    Mutex.lock();
    defer Mutex.unlock();
    return std.fs.File.stdin().read(buf);
}
/// Works only on terminals that support different colours
pub fn colourPrint(comptime fmt: []const u8, args: anytype, colour: Colour) !void {
    Mutex.lock();
    Mutex.unlock();
    var buf: [5096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(buf[0..buf.len]);
    if (State.getTerminalColourSupport()) {
        try stdout.interface.print("\x1b[38;2;{d};{d};{d}m", .{colour.rgba.r, colour.rgba.g, colour.rgba.b});
        try stdout.interface.print(fmt, args);
        try stdout.interface.print("\x1b[0m", .{});
        try stdout.interface.flush();
    } else {
        try stdout.interface.print(fmt, args);
        try stdout.interface.flush();
    }
}