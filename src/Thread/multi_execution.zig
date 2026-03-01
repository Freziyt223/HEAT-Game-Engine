const std = @import("std");
const ztracy = @import("ztracy");
const State = @import("State");

pub const Queue = struct {
    const Self = @This();

    pub const Call = struct {
        args_ptr: *anyopaque,
        exec_fn: *const fn (ptr: *anyopaque) void,
        deinit_fn: *const fn (ptr: *anyopaque, alloc: std.mem.Allocator) void,
    };

    mutex: std.Thread.Mutex = .{},

    queue: std.ArrayList(Call),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .queue = try std.ArrayList(Call).initCapacity(allocator, 0),
        };
    }

    pub fn push(self: *Self, comptime function: anytype, args: anytype, comptime ReturnType: type, return_address: ?*?ReturnType, done: ?*bool) void {
        const ArgsType = @TypeOf(args);
        
        const Stored = struct {
            args: ArgsType,
            ret_ptr: ?*?ReturnType,
            done: ?*bool,
        };

        const stored_args = self.allocator.create(Stored) catch {@panic("Couldn't store args on heap(no memory available)\n");};
        stored_args.* = .{
            .args = args,
            .ret_ptr = return_address,
            .done = done
        };

        const Wrapper = struct {
            fn exec(ptr: *anyopaque) void {
                const typed = @as(*Stored, @ptrCast(@alignCast(ptr)));

                const value: ReturnType =
                    @call(.auto, function, typed.args);

                if (typed.ret_ptr) |p|
                    p.* = value;
                if (typed.done) |d|
                    d.* = true;
            }
            fn deinit(ptr: *anyopaque, alloc: std.mem.Allocator) void {
                const typed_args = @as(*Stored, @ptrCast(@alignCast(ptr)));
                alloc.destroy(typed_args);
            }
        };

        self.mutex.lock();
        defer self.mutex.unlock();
        
        self.queue.append(self.allocator, .{
            .args_ptr = stored_args,
            .exec_fn = Wrapper.exec,
            .deinit_fn = Wrapper.deinit,
        }) catch {@panic("Couldn't append to queue(no memory available)\n");};
    }
};
pub const QueueError = error {
    MissingReturnValue
};
pub const ExecutionQueue = struct{
    queue: Queue,
    running: bool = true,
    threads: []std.Thread,
    cond: std.Thread.Condition = .{},
    ret_cond: std.Thread.Condition = .{},

    pub fn worker(self: *ExecutionQueue) void {
        while (self.running) {
            self.queue.mutex.lock();

            while (self.queue.queue.items.len == 0 and self.running) {
                self.cond.wait(&self.queue.mutex);
            }

            if (!self.running) {
                self.queue.mutex.unlock();
                break;
            }

            const task = self.queue.queue.swapRemove(0);
            self.queue.mutex.unlock();

            defer task.deinit_fn(task.args_ptr, self.queue.allocator);
            errdefer task.deinit_fn(task.args_ptr, self.queue.allocator);
            task.exec_fn(task.args_ptr);
            self.ret_cond.signal();
        }
    }

    pub fn init(self: *ExecutionQueue, threads_slice: []std.Thread, allocator: std.mem.Allocator) !void {
        self.queue = try Queue.init(allocator);
        self.threads = threads_slice;
        self.running = true;

        for (self.threads) |*thread| {
            thread.* = try std.Thread.spawn(.{ .allocator = allocator }, worker, .{self});
        }
    }
    pub fn submit(self: *ExecutionQueue, comptime function: anytype, args: anytype) void {
        self.queue.push(function, args, @typeInfo(@TypeOf(function)).@"fn".return_type.?, null, null);
        self.cond.signal();
    }
    pub fn submitWithReturn(self: *ExecutionQueue, comptime function: anytype, args: anytype) @typeInfo(@TypeOf(function)).@"fn".return_type.? {
        if (!State.MultiThreading) return @call(.auto, function, args);
        const ReturnType = @typeInfo(@TypeOf(function)).@"fn".return_type.?;
        var ret: ?ReturnType = null;
        var done: bool = false;
        self.queue.push(function, args, ReturnType, &ret, &done);
            while (!done and self.running) {}

        if (ret) |value| return value else @panic("Missing return value\n");
    }
    
    pub fn deinit(self: *ExecutionQueue) void {
        self.running = false;
        self.cond.broadcast(); 
        
        for (self.threads) |thread| thread.join();
        for (self.queue.queue.items) |call| {
            call.deinit_fn(call.args_ptr, self.queue.allocator);
        }
        self.queue.queue.deinit(self.queue.allocator);
        self.queue.allocator.free(self.threads);
    }
};