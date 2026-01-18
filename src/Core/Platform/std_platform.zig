//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
const Platform = @import("Platform");
const Engine = @import("Engine");
var Allocator: *Engine.TrackingAllocator = undefined;


// ----------------------------------------------------------------------------------
// Initializing Platform layer
// ----------------------------------------------------------------------------------
pub fn init(allocator: *Engine.TrackingAllocator) !void {
    Allocator = allocator;
}


// ----------------------------------------------------------------------------------
// File
// ----------------------------------------------------------------------------------
pub const File = Platform.File(struct{
    pub fn print(self: *File, comptime fmt: []const u8, args: anytype) !void {
        // Getting an std file from our file struct
        if (self.handle == null) return error.NullHandle;
        const file = std.fs.File{.handle = self.handle.?};
        // Allocating buffer to write text there and then pass it to print
        const allocator = Allocator.allocator();
        var buf = try allocator.alloc(u8, std.fmt.count(fmt, args));
        defer allocator.free(buf);
        // Std print
        var stream = file.writer(buf[0..]);
        try stream.interface.print(fmt, args);
        try stream.interface.flush();
    }

    pub fn write(self: *File, buf: []u8) !usize {
        if (self.handle == null) return error.NullHandle;
        const file = std.fs.File{.handle = self.handle.?};
        return file.write(buf);
    }

    pub fn read(self: *File, buf: []u8) !usize {
        if (self.handle == null) return error.NullHandle;
        const file = std.fs.File{.handle = self.handle.?};
        return file.read(buf);
    }

    pub fn stdout() File {
        return File{
            .handle = std.fs.File.stdout().handle
        };
    }

    pub fn stderr() File {
        return File{
            .handle = std.fs.File.stdin().handle
        };
    }

    pub fn stdin() File {
        return File{
            .handle = std.fs.File.stderr().handle
        };
    }  
});