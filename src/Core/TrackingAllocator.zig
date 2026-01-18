//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
pub var TotalAllocated: usize = 0;
const Self = @This();
// This field will only be initialized on making an allocator
InternalAllocator: std.mem.Allocator,
Category: []const u8,


// ----------------------------------------------------------------------------------
// Function to return an actual allocator that will be 
// ----------------------------------------------------------------------------------
pub fn allocator(self: *Self) std.mem.Allocator {
    return std.mem.Allocator{
        .ptr = self,
        .vtable = &.{
            .alloc = &alloc,
            .resize = &resize,
            .free = &free,
            .remap = &remap,
        }
    };
}


// ----------------------------------------------------------------------------------
// Allocator tracking functions
// ----------------------------------------------------------------------------------
fn alloc(state: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(state));
    const result = self.InternalAllocator.vtable.alloc(self.InternalAllocator.ptr, len, alignment, ret_addr);
    if (result != null) TotalAllocated += len;
    return result;
}
fn resize(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *Self = @ptrCast(@alignCast(state));
    const result = self.InternalAllocator.vtable.resize(self.InternalAllocator.ptr, buf, alignment, new_len, ret_addr);
    if (result) {
        if (new_len > buf.len) {
            TotalAllocated += new_len - buf.len;
        } else {
            TotalAllocated -= buf.len - new_len;
        }
    }
    return result;
}
fn free(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const self: *Self = @ptrCast(@alignCast(state));
    TotalAllocated -= buf.len;
    self.InternalAllocator.vtable.free(self.InternalAllocator.ptr, buf, alignment, ret_addr);
}
fn remap(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(state));
    const result = self.InternalAllocator.vtable.remap(self.InternalAllocator.ptr, buf, alignment, new_len, ret_addr);
    if (result != null) {
        if (new_len > buf.len) {
            TotalAllocated += new_len - buf.len;
        } else {
            TotalAllocated -= buf.len - new_len;
        }
    }
    return result;
}
