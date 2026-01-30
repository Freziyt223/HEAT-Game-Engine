// =========================================================================================
// Imports
const std = @import("std");
const Engine = @import("Root");
pub var Allocator = &Engine.InternalAllocator;


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
        const allocator = Allocator.allocator();
        const buf = try std.fmt.allocPrint(allocator, fmt, args);
        defer allocator.free(buf);

        return std.fs.File.stdout().writeAll(buf);
    }
    pub fn Read(buf: []u8) !usize {
        return std.fs.File.stdin().read(buf);
    }
    /// Works only on terminals that support different colours
    pub fn ColourPrint(comptime fmt: []const u8, args: anytype, colour: Colour) !void {
        const allocator = Allocator.allocator();
        const message = try std.fmt.allocPrint(allocator, fmt, args);
        defer allocator.free(message);

        return Console.Print("\x1b[38;2;{d};{d};{d}m{s}\x1b[0m", .{colour.rgba.r, colour.rgba.g, colour.rgba.b, message});
    }
};


// =========================================================================================
// FileSystem
pub const FileSystem = std.fs;
