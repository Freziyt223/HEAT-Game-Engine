// =========================================================================================
// Imports
const std = @import("std");
const Engine = @import("Root");
pub var Allocator = &Engine.InternalAllocator;
pub var IO: std.Io = undefined;



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
    pub fn Print(comptime fmt: []const u8, args: anytype) !void {
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console print", 0xFF0000);
        defer Zone.End();
        const allocator = Allocator.allocator();
        const count = std.fmt.count(fmt, args);
        const buf = try allocator.alloc(u8, count);
        defer allocator.free(buf);
        var stdout = std.Io.File.stdout().writer(IO, buf);

        try stdout.interface.print(fmt, args);
        try stdout.flush();
    }
    pub fn Read(buf: []u8) !usize {
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console read", 0xFF0000);
        defer Zone.End();
        return std.Io.File.stdin().readStreamingAll(IO, buf);
    }
    /// Works only on terminals that support different colours
    pub fn ColourPrint(comptime fmt: []const u8, args: anytype, colour: Colour) !void {
        const Zone = Engine.ztracy.ZoneNC(@src(), "Console colour crint", 0xFF0000);
        defer Zone.End();
        const allocator = Allocator.allocator();
        const message = try std.fmt.allocPrint(allocator, fmt, args);
        defer allocator.free(message);

        return Console.Print("\x1b[38;2;{d};{d};{d}m{s}\x1b[0m", .{colour.rgba.r, colour.rgba.g, colour.rgba.b, message});
    }
};


// =========================================================================================
// FileSystem
pub const FileSystem = std.Io;
