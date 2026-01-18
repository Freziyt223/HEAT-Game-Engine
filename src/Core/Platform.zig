//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");


// ----------------------------------------------------------------------------------
// File operations segment
// ----------------------------------------------------------------------------------
pub fn File(comptime Impl: type) type {
    return struct {
        const Self = @This();

        handle: ?*anyopaque,

        pub fn print(self: *Self, comptime fmt: []const u8, args: anytype) anyerror!void {
            return Impl.print(self, fmt, args);
        }

        pub fn write(self: *Self, buf: []u8) anyerror!usize {
            return Impl.write(self, buf);
        }

        pub fn read(self: *Self, buf: []u8) anyerror!usize {
            return Impl.read(self, buf);
        }

        pub fn read_plain(self: *Self, buf: []u8) !usize {
            return self.read(buf);
        }

        pub fn stdout() Self {
            return Impl.stdout();
        }

        pub fn stderr() Self {
            return Impl.stderr();
        }

        pub fn stdin() Self {
            return Impl.stdin();
        }
    };
}

pub const FileError = error {
    NullHandle
};

