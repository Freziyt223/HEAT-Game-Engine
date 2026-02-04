const std = @import("std");
const User = @import("User");
const State = @import("State");
const ztracy = @import("ztracy");
const Thread = @import("Thread");
const Root = @import("Root");
const TrackingAllocator = @import("TrackingAllocator");
pub var QueueAllocator = TrackingAllocator{.Allocator = std.heap.page_allocator, .Category = "Execution queue"};


// To optimize runtime we do checks in runtime and for while loop we select 
// while loop that has only declarated fields so it doesn't need to check
// for existance of the same value each time
pub fn main() !void {
    const Zone = ztracy.ZoneN(@src(), "Main");
    defer Zone.End();
    ztracy.SetThreadName("Main");

    // conf will run before any other code
    const ConfZone = ztracy.ZoneN(@src(), "Conf");
    if (@hasDecl(User, "conf")) User.conf();
    ConfZone.End();
    
    const InitZone = ztracy.ZoneN(@src(), "Init");
    if (@hasDecl(User, "init")) try User.init();
    InitZone.End();
    defer if (@hasDecl(User, "deinit")) User.deinit();
    // Update loop
    Thread.ThreadCount = try std.Thread.getCpuCount();
    if (Thread.ThreadCount == 1) try SingleThreading()
    else try MultiThreading();
   
}

fn MultiThreading() !void {
    const allocator = Root.InternalAllocator.allocator();
    const Threads = try allocator.alloc(std.Thread, Thread.ThreadCount - 1);
     
    try Thread.Threads.init(Threads[0..Thread.ThreadCount - 1], QueueAllocator.allocator());
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
            const now = Timer.read();
            inline for (User.update, 0..) |update_struct, i| {
                if (@hasDecl(update_struct, "update")) {
                    const rate = &Tick_Rates[i];
                    if (rate.interval != 0) {if (now - rate.last >= rate.interval) {
                        rate.last += rate.interval;
                        try Thread.Threads.submit(&update_struct.update, .{});
                    }}
                    else try Thread.Threads.submit(&update_struct.update, .{});
                }
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
            const now = Timer.read();
            inline for (User.update, 0..) |update_struct, i| {
                if (@hasDecl(update_struct, "update")) {
                    const rate = &Tick_Rates[i];
                    if (rate.interval != 0) {if (now - rate.last >= rate.interval) {
                        rate.last += rate.interval;
                        try update_struct.update();
                    }}
                    else try update_struct.update();
                }
            }
        }
        Loop.End();
    }
}