//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
const Platform = @import("Platform");


// ----------------------------------------------------------------------------------
// File
// ----------------------------------------------------------------------------------
pub const File = Platform.File{
    .handle = null,
    .print = &print,
    .write = &write,
    .read = &read,
    .stdout = &stdout,
    .stderr = &stderr,
    .stdin = &stdin,
};

fn print(self: *File, comptime _: []const u8, _: anytype) !void {
    if (self.handle == null) return error.NullHandle;

}

fn write(self: *File, _: []u8) !usize {
    if (self.handle == null) return error.NullHandle;
}

fn read(self: *File, _: []u8) !void {
    if (self.handle == null) return error.NullHandle;
}

fn stdout() File {

}

fn stderr() File {

}

fn stdin() File {

}