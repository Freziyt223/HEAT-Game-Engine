//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");


// ----------------------------------------------------------------------------------
// File operations segment
// ----------------------------------------------------------------------------------
pub fn FileSystem(comptime File_Impl: type, comptime Dir_Impl: type, comptime Impl: type) type {
    return struct {
        pub const File = struct {
            const Self = @This();
            pub const OpenFlags = std.fs.File.OpenFlags;

            handle: ?*anyopaque,

            pub fn print(self: Self, comptime fmt: []const u8, args: anytype) anyerror!void {
                return File_Impl.print(self, fmt, args);
            }

            pub fn write(self: Self, buf: []u8) anyerror!usize {
                return File_Impl.write(self, buf);
            }

            pub fn read(self: Self, buf: []u8) anyerror!usize {
                return File_Impl.read(self, buf);
            }

            pub fn stdout() Self {
                return File_Impl.stdout();
            }

            pub fn stderr() Self {
                return File_Impl.stderr();
            }

            pub fn stdin() Self {
                return File_Impl.stdin();
            }

            pub fn close(self: Self) void {
                return File_Impl.close(self);
            }
        };
        pub const Dir = struct {
            const Self = @This();
            pub const OpenOptions = std.fs.Dir.OpenOptions;

            handle: ?*anyopaque,
            pub fn openDir(self: Self, path: []const u8, flags: OpenOptions) !Self {
                return Dir_Impl.openDir(self, path, flags);
            }

            pub fn openFile(self: Self, path: []const u8, flags: File.OpenFlags) !File {
                return Dir_Impl.openFile(self, path, flags);
            }

            pub fn close(self: Self) void {
                return Dir_Impl.close(self);
            }
        };

        pub fn cwd() Dir {
            return Impl.cwd();
        }
    };
}

pub const FileError = error {
    NullHandle
};


// ----------------------------------------------------------------------------------
// Window segment
// ----------------------------------------------------------------------------------
pub fn Window(comptime _: type) type {

}