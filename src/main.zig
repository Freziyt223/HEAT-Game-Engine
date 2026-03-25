const std = @import("std");
const User = @import("User");
const State = @import("State");
const Conf = State.conf;
const Thread = @import("Thread");
const TrackingAllocator = @import("TrackingAllocator");
const IO = @import("IO");
const buildOptions = @import("buildOptions");

pub const main = if (@hasDecl(User, "main")) User.main else mainImpl;

pub fn mainImpl() !void {
    State.setThreadCount(try std.Thread.getCpuCount());
    State.setTotalMemory(@intCast(try std.process.totalSystemMemory()));
    Thread.MainThreadId = std.Thread.getCurrentId();

    if (State.isSingleThreaded() or buildOptions.singlethreaded) try singleThreaded()
    else try multithreaded();
}

fn singleThreaded() !void {
    var gpa = std.heap.DebugAllocator(.{.thread_safe = false, .enable_memory_limit = false}).init;
    defer std.debug.assert(gpa.deinit() == .ok);

    if (@hasDecl(User, "conf")) User.conf();

    var InitAllocator = TrackingAllocator.init(Conf.InitAllocator orelse gpa.allocator(), "UserInit");
    var UserAllocator = TrackingAllocator.init(gpa.allocator(), "User");


    var args = try std.process.argsWithAllocator(InitAllocator.allocator());
    defer args.deinit();
    if (@hasDecl(User, "init")) try User.init(.{.allocator = UserAllocator.allocator(), .args = &args});
    if (@hasDecl(User, "update")) {
        switch (@typeInfo(@TypeOf(User.update))) {
            .@"fn" => {
                while (State.isRunning()) {
                    try User.update();
                }
            },
            .array => {
                var Timer = try std.time.Timer.start();
                var Tick_Rates: [User.update.len]struct {
                    last: u64,
                    interval: u64
                } = undefined;

                inline for (User.update, 0..) |update_struct, i| {
                    if (update_struct.tick_rate) |rate| {
                        Tick_Rates[i] = .{ .last = 0, .interval = std.time.ns_per_s / rate };
                    } else {
                        Tick_Rates[i] = .{ .last = 0, .interval = 0 };
                    }
                }

                while (State.isRunning()) {
                    const now = Timer.read();
                    inline for (User.update, 0..) |update_struct, i| {
                        const rate = &Tick_Rates[i];
                        if (rate.interval != 0) {
                            if (now - rate.last >= rate.interval) {
                                rate.last += rate.interval;
                                if (@hasDecl(update_struct, "update")) try update_struct.update(update_struct{});
                            }
                        }
                        else {
                            if (@hasDecl(update_struct, "update")) try update_struct.update(update_struct{});
                        }
                    }
                }
            },
            else => {@panic("Wrong update type(nor a function or array of structs)");}
        }
    }
}

fn multithreaded() !void {
    var gpa = std.heap.DebugAllocator(.{.thread_safe = true, .enable_memory_limit = false}).init;
    defer std.debug.assert(gpa.deinit() == .ok);

    if (@hasDecl(User, "conf")) User.conf();
    
    var InitAllocator = TrackingAllocator.init(Conf.InitAllocator orelse gpa.allocator(), "UserInit");
    var UserAllocator = TrackingAllocator.init(gpa.allocator(), "User");
    var QueueAllocator = TrackingAllocator.init(Conf.JobQueueAllocator orelse gpa.allocator(), "JobQueue");

    var args = try std.process.argsWithAllocator(InitAllocator.allocator());
    defer args.deinit();
    if (@hasDecl(User, "init")) try User.init(.{.allocator = UserAllocator.allocator(), .args = &args});
    if (@hasDecl(User, "update")) {
        switch (@typeInfo(@TypeOf(User.update))) {
            .@"fn" => {
                while (State.isRunning()) {
                    try User.update();
                }
            },
            .array => {
                var Timer = try std.time.Timer.start();
                var Tick_Rates: [User.update.len]struct {
                    last: u64,
                    interval: u64
                } = undefined;

                inline for (User.update, 0..) |update_struct, i| {
                    if (update_struct.tick_rate) |rate| {
                        Tick_Rates[i] = .{ .last = 0, .interval = std.time.ns_per_s / rate };
                    } else {
                        Tick_Rates[i] = .{ .last = 0, .interval = 0 };
                    }
                }

                while (State.isRunning()) {
                    const now = Timer.read();
                    inline for (User.update, 0..) |update_struct, i| {
                        const rate = &Tick_Rates[i];
                        if (rate.interval != 0) {
                            if (now - rate.last >= rate.interval) {
                                rate.last += rate.interval;
                                if (@hasDecl(update_struct, "update")) try update_struct.update(update_struct{});
                            }
                        }
                        else {
                            if (@hasDecl(update_struct, "update")) try update_struct.update(update_struct{});
                        }
                    }
                }
            },
            else => {@panic("Wrong update type(nor a function or array of structs)");}
        }
    }
}