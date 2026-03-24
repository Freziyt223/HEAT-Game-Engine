const std = @import("std");
const ztracy = @import("ztracy");
const State = @import("State");

const Self = @This();

Allocated: std.atomic.Value(usize) = .{ .raw = 0 },
Category: [*:0]const u8,
InternalAllocator: std.mem.Allocator,

const tracking_vtable = std.mem.Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
    .remap = remap,
};

pub fn init(Allocator: std.mem.Allocator, category: [*:0]const u8) Self {
    return .{
        .InternalAllocator = Allocator,
        .Category = category,
    };
}

pub fn allocator(self: *Self) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &tracking_vtable,
    };
}

fn shouldTrack(self: *Self) bool {
    return self.InternalAllocator.vtable != &tracking_vtable;
}

fn alloc(state: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(state));

    const res = self.InternalAllocator.vtable.alloc(
        self.InternalAllocator.ptr,
        len,
        alignment,
        ret_addr,
    );

    if (!shouldTrack(self)) return res;

    if (res) |ptr| {
        ztracy.AllocN(ptr, len, self.Category);
        _ = self.Allocated.fetchAdd(len, .monotonic);
        State.changeUsedMemory(@intCast(len));
    }

    return res;
}

fn free(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const self: *Self = @ptrCast(@alignCast(state));

    self.InternalAllocator.vtable.free(
        self.InternalAllocator.ptr,
        buf,
        alignment,
        ret_addr,
    );

    if (!shouldTrack(self)) return;

    ztracy.FreeN(buf.ptr, self.Category);
    _ = self.Allocated.fetchSub(buf.len, .monotonic);
    State.changeUsedMemory(-@as(isize, @intCast(buf.len)));
}

fn resize(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *Self = @ptrCast(@alignCast(state));

    const ok = self.InternalAllocator.vtable.resize(
        self.InternalAllocator.ptr,
        buf,
        alignment,
        new_len,
        ret_addr,
    );

    if (!ok) return false;
    if (!shouldTrack(self)) return true;

    if (new_len > buf.len) {
        const diff = new_len - buf.len;
        _ = self.Allocated.fetchAdd(diff, .monotonic);
        State.changeUsedMemory(@intCast(diff));
    } else if (new_len < buf.len) {
        const diff = buf.len - new_len;
        _ = self.Allocated.fetchSub(diff, .monotonic);
        State.changeUsedMemory(-@as(isize, @intCast(diff)));
    }

    ztracy.FreeN(buf.ptr, self.Category);
    ztracy.AllocN(buf.ptr, new_len, self.Category);

    return true;
}

fn remap(state: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *Self = @ptrCast(@alignCast(state));

    const res = self.InternalAllocator.vtable.remap(
        self.InternalAllocator.ptr,
        buf,
        alignment,
        new_len,
        ret_addr,
    );

    if (!shouldTrack(self)) return res;

    if (res) |ptr| {
        ztracy.FreeN(buf.ptr, self.Category);
        ztracy.AllocN(ptr, new_len, self.Category);

        if (new_len > buf.len) {
            const diff = new_len - buf.len;
            _ = self.Allocated.fetchAdd(diff, .monotonic);
            State.changeUsedMemory(@intCast(diff));
        } else if (new_len < buf.len) {
            const diff = buf.len - new_len;
            _ = self.Allocated.fetchSub(diff, .monotonic);
            State.changeUsedMemory(-@as(isize, @intCast(diff)));
        }
    }

    return res;
}