// =========================================================================================
// Imports
const std = @import("std");
const Engine = @import("Root");
pub var Allocator = &Engine.InternalAllocator;

pub var EnableLogging: bool = false;
pub var LogLocation: []const u8 = "logs/latest.txt";


// =========================================================================================
// Usefull fields
pub const Colour = extern union {
    // Values from Hex are represented as bytes and u32 is separated into
    // two halfs called endians, where little one to the right(if you write from left to right)
    // So in memory endians are swapped, so hex 0xFFEEDD00(red) will be 0xDD00FFEE
    // So that's why we have them in like this
    rgba: extern struct {b: u8, a: u8, r: u8, g: u8},
    Hex: u32,
};

// =========================================================================================
// Console IO
pub const Console = struct {
    var Mutex = std.Thread.Mutex{};
    pub fn Print(comptime fmt: []const u8, args: anytype) !void {
        Mutex.lock();
        defer Mutex.unlock();
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console print", 0xFF0000);
        defer Zone.End();
        var buf: [1024]u8 = undefined;
        var stdout = std.fs.File.stdout().writer(buf[0..buf.len]);
        try stdout.interface.print(fmt, args);
        try stdout.interface.flush();

    }
    pub fn Read(buf: []u8) !usize {
        Mutex.lock();
        defer Mutex.unlock();
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console read", 0xFF0000);
        defer Zone.End();
        return std.fs.File.stdin().read(buf);
    }
    /// Works only on terminals that support different colours
    pub fn ColourPrint(comptime fmt: []const u8, args: anytype, colour: Colour) !void {
        Mutex.lock();
        defer Mutex.unlock();
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console colour crint", 0xFFEE00);
        defer Zone.End();
        var buf: [1024]u8 = undefined;
        var stdout = std.fs.File.stdout().writer(buf[0..buf.len]);
        try stdout.interface.print("\x1b[38;2;{d};{d};{d}m", .{colour.rgba.r, colour.rgba.g, colour.rgba.b});
        try stdout.interface.print(fmt, args);
        try stdout.interface.print("\x1b[0m", .{});
        try stdout.interface.flush();
    }
};


// =========================================================================================
// FileSystem
pub const FileSystem = std.fs;