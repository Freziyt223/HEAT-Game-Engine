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
pub const FileSystem = Platform.FileSystem(
    struct{
        pub fn print(self: FileSystem.File, comptime fmt: []const u8, args: anytype) !void {
            // Getting an std file from our file struct
            if (self.handle == null) return error.NullHandle;
            // Allocating buffer to write text there and then pass it to print
            const allocator = Allocator.allocator();
            var buf = try allocator.alloc(u8, std.fmt.count(fmt, args));
            defer allocator.free(buf);
            // Converting to UTF16 and doing windows print
            const new_buf = try std.unicode.utf8ToUtf16LeAlloc(allocator, try std.fmt.bufPrint(buf[0..buf.len], fmt, args));
            std.os.windows.kernel32.WriteConsoleW(FileSystem.File.stdout().handle, new_buf, @intCast(buf.len), null, null);
        }

        pub fn write(self: FileSystem.File, buf: []u8) !usize {
            if (self.handle == null) return error.NullHandle;
            const file = std.fs.File{.handle = self.handle.?};
            return file.write(buf);
        }

        pub fn read(self: FileSystem.File, buf: []u8) !usize {
            if (self.handle == null) return error.NullHandle;
            const file = std.fs.File{.handle = self.handle.?};
            return file.read(buf);
        }

        pub fn stdout() FileSystem.File {
            return FileSystem.File{
                .handle = std.os.windows.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE)
            };
        }

        pub fn stderr() FileSystem.File {
            return FileSystem.File{
                .handle = std.os.windows.GetStdHandle(std.os.windows.STD_ERROR_HANDLE)
            };
        }

        pub fn stdin() FileSystem.File {
            return FileSystem.File{
                .handle = std.os.windows.GetStdHandle(std.os.windows.STD_INPUT_HANDLE)
            };
        } 

        pub fn close(self: FileSystem.File) void {
            if (self.handle == null) return;
            std.os.windows.CloseHandle(self.handle.?);
        }
    },
    struct{
        pub fn openFile(self: FileSystem.Dir, path: []const u8, flags: FileSystem.File.OpenFlags) !FileSystem.File {
            const dir = std.fs.Dir{.fd = self.handle.?};
            const file = try dir.openFile(path, flags);
            return FileSystem.File{.handle = @ptrCast(file.handle)};
        }

        pub fn openDir(self: FileSystem.Dir, path: []const u8, flags: FileSystem.Dir.OpenOptions) !FileSystem.Dir {
            const dir = std.fs.Dir{.fd = self.handle.?};
            const in_dir = try dir.openDir(path, flags);
            return FileSystem.Dir{.handle = in_dir.fd};
        }

        pub fn close(self: *FileSystem.Dir) void {
            const dir = std.fs.Dir{.fd = self.handle.?};
            dir.close();
        }
    },
    struct {
        pub fn cwd() FileSystem.Dir {
            const dir = std.fs.cwd();
            return .{.handle = dir.fd};
        }
    }
);