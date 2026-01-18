//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
const TrackingAllocator = @import("TrackingAllocator.zig");
const Platform = @import("Platform");
const Colour_T = @import("Colour.zig");
const Utils = @import("Utils.zig");
const Self = @This();
var Allocator: *TrackingAllocator = undefined;


// ----------------------------------------------------------------------------------
// Initializing IO layer
// ----------------------------------------------------------------------------------
pub fn init(allocator: *TrackingAllocator) !void {
    Allocator = allocator;
}


// ----------------------------------------------------------------------------------
// Printing
// ----------------------------------------------------------------------------------
pub const Console = struct {
    pub fn Print(comptime fmt: []const u8, args: anytype) !void {
        var out = Platform.File.stdout();
        return out.print(fmt, args);
    }
    pub fn Error(comptime fmt: []const u8, args: anytype) !void {
        var err = Platform.File.stderr();
        return err.print(fmt, args);
    }
    pub fn Read(buf: []u8) !usize {
        var in = Platform.File.stdin();
        return in.read(buf);
    }
    pub const Colour = struct {
        pub fn colourPrint(comptime fmt: []const u8, args: anytype, colour: Colour_T.Colour) !void {
            const allocator = Allocator.allocator();
            var buf = try allocator.alloc(u8, std.fmt.count(fmt, args));
            defer allocator.free(buf);
            try std.fmt.bufPrint(buf[0..buf.len], fmt, args);
            try Console.Print("\x1b[38;2;{d};{d};{d};m{s}", .{colour.rgba.r, colour.rgba.g, colour.rgba.b, buf});
        }

        pub fn colourError(comptime fmt: []const u8, args: anytype, colour: Colour_T.Colour) !void {
            const allocator = Allocator.allocator();
            var buf = try allocator.alloc(u8, std.fmt.count(fmt, args));
            defer allocator.free(buf);
            try std.fmt.bufPrint(buf[0..buf.len], fmt, args);
            try Console.Error("\x1b[38;2;{d};{d};{d};m{s}", .{colour.rgba.r, colour.rgba.g, colour.rgba.b, buf});
        }
    };
};


// ----------------------------------------------------------------------------------
// File management
// ----------------------------------------------------------------------------------
pub const File = Platform.File;