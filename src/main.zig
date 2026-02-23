const std = @import("std");
const User = @import("User");
const State = @import("State");
const ztracy = @import("ztracy");
const Renderer = @import("Renderer");
const Thread = @import("Thread");
const Root = @import("Root");
const TrackingAllocator = @import("TrackingAllocator");
const buildOptions = @import("buildOptions");
// To optimize runtime we do checks in runtime and for while loop we select 
// while loop that has only declarated fields so it doesn't need to check
// for existance of the same value each time
pub fn main() !void {
    const Zone = ztracy.ZoneN(@src(), "Main");
    defer Zone.End();
    ztracy.SetThreadName("Main");

    Thread.ThreadCount = try std.Thread.getCpuCount();
    const SingleThread = std.heap.DebugAllocator(.{});
    const MultiThread = std.heap.DebugAllocator(.{.thread_safe = true});
    var gpa = if (Thread.ThreadCount > 1) MultiThread.init else SingleThread.init;
    defer std.debug.assert(gpa.deinit() == .ok);

    State.MemoryCapacity = @as(usize, @intCast(try std.process.totalSystemMemory()));

    Root.InternalAllocator = TrackingAllocator{.Allocator = gpa.allocator(), .Category = "Internal"};
    Root.QueueAllocator = TrackingAllocator{.Allocator = gpa.allocator(), .Category = "Queue"};

    try Renderer.zglfw.init();
    defer Renderer.zglfw.terminate();
    // conf will overwrite things 
    const ConfZone = ztracy.ZoneN(@src(), "Conf");
    if (@hasDecl(User, "conf")) User.conf();
    ConfZone.End();
    var arg = try std.process.argsWithAllocator(Root.InternalAllocator.allocator());
    defer arg.deinit();
    const InitZone = ztracy.ZoneN(@src(), "Init");
    if (@hasDecl(User, "init")) {
        try User.init(.{ .Args = arg, .Allocator = gpa.allocator() });
    }
    InitZone.End();
    defer if (@hasDecl(User, "deinit")) User.deinit();
    // Update loop
    
    if (Thread.ThreadCount == 1) try SingleThreading()
    else try MultiThreading();
    //try SingleThreading();
}

fn MultiThreading() !void {
    const allocator = Root.QueueAllocator.allocator();
    const Threads = try allocator.alloc(std.Thread, Thread.ThreadCount - 1);
     
    try Thread.Threads.init(Threads[0..Thread.ThreadCount - 1], Root.QueueAllocator.allocator());
    defer Thread.Threads.deinit();
    
    if (@hasDecl(User, "update")) {
        const Loop = ztracy.ZoneNC(@src(), "Update loop", 0xB96447);
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

        while (State.Running) {
            Renderer.zglfw.pollEvents();
            const now = Timer.read();
            inline for (User.update, 0..) |update_struct, i| {
                const rate = &Tick_Rates[i];
                if (rate.interval != 0) if (now - rate.last >= rate.interval) {
                    rate.last += rate.interval;
                    if (@hasDecl(update_struct, "update")) try Thread.Threads.submit(&update_struct.update, .{});
                    if (@hasDecl(update_struct, "main")) try update_struct.main();
                }
                else {
                    if (@hasDecl(update_struct, "update")) try Thread.Threads.submit(&update_struct.update, .{});
                    if (@hasDecl(update_struct, "main")) try update_struct.main();
                };
            }
        }
        Loop.End();
    }
}

fn SingleThreading() !void {
    if (@hasDecl(User, "update")) {
        const Loop = ztracy.ZoneNC(@src(), "Update loop", 0xB96447);
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

        while (State.Running) {
            Renderer.zglfw.pollEvents();
            const now = Timer.read();
            inline for (User.update, 0..) |update_struct, i| {
                const rate = &Tick_Rates[i];
                if (rate.interval != 0) if (now - rate.last >= rate.interval) {
                    rate.last += rate.interval;
                    if (@hasDecl(update_struct, "main")) try update_struct.main();
                    if (@hasDecl(update_struct, "update")) try update_struct.update();
                } else {
                    if (@hasDecl(update_struct, "main")) try update_struct.main();
                    if (@hasDecl(update_struct, "update")) try update_struct.update();
                };
            }
        }
        Loop.End();
    }
}