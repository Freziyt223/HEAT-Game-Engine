const std = @import("std");
pub const ztracy = @import("ztracy");
pub const FileSystem = std.fs;
pub const IO = @import("IO");
pub const Init = struct {
    allocator: std.mem.Allocator,
    args: *std.process.ArgIterator
};