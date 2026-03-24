const std = @import("std");
pub const conf = @import("conf.zig");

var vtable: struct {
    ThreadCount: std.atomic.Value(u64) = .{ .raw = 1 },
    NumberOfUsedThreads: std.atomic.Value(u64) = .{ .raw = 1 },
    MaxMemory: std.atomic.Value(usize) = .{ .raw = 0 },
    UsedMemory: std.atomic.Value(usize) = .{ .raw = 0 },
    PeakMemoryUsage: std.atomic.Value(usize) = .{ .raw = 0 },
    Running: std.atomic.Value(bool) = .{ .raw = true },
    TerminalColourSupport: std.atomic.Value(bool) = .{ .raw = true }
} = .{};

pub fn isSingleThreaded() bool {
    if (vtable.ThreadCount.load(.seq_cst) == 1) return true else return false;
}
pub fn isRunning() bool {
    return vtable.Running.load(.acquire);
}

pub fn setThreadCount(num: u64) void {
    vtable.ThreadCount.store(num, .seq_cst);
}
pub fn getThreadCount() u64 {
    return vtable.ThreadCount.load(.seq_cst);
}

pub fn setNumberOfUsedThreads(num: u64) void {
    vtable.NumberOfUsedThreads.store(num, .seq_cst);
}
pub fn getNumberOfUsedThreads() u64 {
    return vtable.NumberOfUsedThreads.load(.seq_cst);
}

pub fn stopRunning() void {
    vtable.Running.store(false, .release);
}

pub fn setTotalMemory(value: usize) void {
    vtable.MaxMemory.store(value, .seq_cst);
}
pub fn getTotalMemory() usize {
    return vtable.MaxMemory.load(.seq_cst);
}

pub fn changeUsedMemory(delta: isize) void {
    if (delta >= 0) {
        const prev = vtable.UsedMemory.fetchAdd(@as(usize, @intCast(delta)), .monotonic);
        const new_used = prev + @as(usize, @intCast(delta));

        var peak = vtable.PeakMemoryUsage.load(.seq_cst);
        while (new_used > peak) : (peak = vtable.PeakMemoryUsage.load(.seq_cst)) {
            if (vtable.PeakMemoryUsage.cmpxchgStrong(peak, new_used, .seq_cst, .seq_cst)) |_| break
            else continue;
        }
    } else {
        const delta_usize = @as(usize, @intCast(-delta));
        const prev = vtable.UsedMemory.fetchSub(delta_usize, .monotonic);

        if (delta_usize > prev) {
            vtable.UsedMemory.store(0, .seq_cst);
        }
    }
}

pub fn getUsedMemory() usize {
    return vtable.UsedMemory.load(.seq_cst);
}
pub fn getPeakMemory() usize {
    return vtable.PeakMemoryUsage.load(.seq_cst);
}

pub fn setTerminalColourSupport(value: bool) void {
    vtable.TerminalColourSupport.store(value, .seq_cst);
}
pub fn getTerminalColourSupport() bool {
    return vtable.TerminalColourSupport.load(.seq_cst);
}