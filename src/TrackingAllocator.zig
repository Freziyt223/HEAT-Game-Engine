//! To use tracking allocator make a struct with it like this:  
//! TrackingAllocator{.Allocator = (your allocator), .Category = "(your category)"}
// =========================================================================================
// Imports and top-level fields
const std = @import("std");
const ztracy = @import("ztracy");
const Self = @This();
pub var TotalAllocated: usize = 0;

// This field will only be initialized on making an allocator
Allocator: std.mem.Allocator,
Allocated: usize = 0,
Category: []const u8,

var InternalAllocator: ztracy.TracyAllocator = undefined;


// =========================================================================================
// Function to return an actual allocator that will be 
pub fn allocator(self: *Self) std.mem.Allocator {
    // This step makes ztracy track allocations(if enabled)
    InternalAllocator = ztracy.TracyAllocator.init(self.Allocator);
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


// =========================================================================================
// Allocator tracking functions
fn alloc(state: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const Zone = ztracy.ZoneN(@src(), "Allocation");
    defer Zone.End();
    const self: *Self = @ptrCast(@alignCast(state));
    const allocat = InternalAllocator.allocator();
    const result = allocat.vtable.alloc(allocat.ptr, len, alignment, ret_addr);
    if (result != null) {
        self.Allocated += len;
        TotalAllocated += len;
    }
    return result;
}
fn resize(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const Zone = ztracy.ZoneN(@src(), "Mem resize");
    defer Zone.End();
    const self: *Self = @ptrCast(@alignCast(state));
    const allocat = InternalAllocator.allocator();
    const result = allocat.vtable.resize(allocat.ptr, buf, alignment, new_len, ret_addr);
    if (result) {
        if (new_len > buf.len) {
            self.Allocated += new_len - buf.len;
            TotalAllocated += new_len - buf.len;
        } else {
            self.Allocated -= buf.len - new_len;
            TotalAllocated -= buf.len - new_len;
        }
    }
    return result;
}
fn free(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const Zone = ztracy.ZoneN(@src(), "Free");
    defer Zone.End();
    const self: *Self = @ptrCast(@alignCast(state));
    const allocat = InternalAllocator.allocator();
    self.Allocated -= buf.len;
    TotalAllocated -= buf.len;
    allocat.vtable.free(allocat.ptr, buf, alignment, ret_addr);
}
fn remap(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const Zone = ztracy.ZoneN(@src(), "Mem remap");
    defer Zone.End();
    const self: *Self = @ptrCast(@alignCast(state));
    const allocat = InternalAllocator.allocator();
    const result = allocat.vtable.remap(allocat.ptr, buf, alignment, new_len, ret_addr);
    if (result != null) {
        if (new_len > buf.len) {
            const delta = new_len - buf.len;
            self.Allocated += delta;
            TotalAllocated += delta;
        } else if (new_len < buf.len) {
            const delta = buf.len - new_len;
            self.Allocated -= delta;
            TotalAllocated -= delta;
        }

    }
    return result;
}
