const std = @import("std");
const ztracy = @import("ztracy");
const State = @import("State");

pub const Queue = struct {
    const Self = @This();

    // Тепер структура call дуже проста і займає мало місця
    pub const Call = struct {
        args_ptr: *anyopaque,
        // Ця функція — "ключ", який знає, як розпакувати args_ptr
        exec_fn: *const fn (ptr: *anyopaque) anyerror!void,
        // Функція для очищення пам'яті за собою
        deinit_fn: *const fn (ptr: *anyopaque, alloc: std.mem.Allocator) void,
    };

    mutex: std.Thread.Mutex = .{},
    // Важливо: ArrayList має бути правильного типу Call
    queue: std.ArrayList(Call),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .queue = try std.ArrayList(Call).initCapacity(allocator, 0),
        };
    }

    // anytype дозволяє передати БУДЬ-ЯКУ функцію та БУДЬ-ЯКІ аргументи
    pub fn push(self: *Self, comptime function: anytype, args: anytype) !void {
        const ArgsType = @TypeOf(args);
        
        const stored_args = try self.allocator.create(ArgsType);
        stored_args.* = args;

        const Wrapper = struct {
            fn exec(ptr: *anyopaque) anyerror!void {
                const typed_args = @as(*const ArgsType, @ptrCast(@alignCast(ptr)));
                // Тепер 'function' доступна, бо вона comptime
                return @call(.auto, function, typed_args.*);
            }
            fn deinit(ptr: *anyopaque, alloc: std.mem.Allocator) void {
                const typed_args = @as(*ArgsType, @ptrCast(@alignCast(ptr)));
                alloc.destroy(typed_args);
            }
        };

        self.mutex.lock();
        defer self.mutex.unlock();
        
        try self.queue.append(self.allocator, .{
            .args_ptr = stored_args,
            .exec_fn = Wrapper.exec,
            .deinit_fn = Wrapper.deinit,
        });
    }
};

pub const ExecutionQueue = struct{
    queue: Queue,
    running: bool = true,
    cond: std.Thread.Condition = .{},

    pub fn init(self: *ExecutionQueue, allocator: std.mem.Allocator) !void {
        self.queue = try Queue.init(allocator);
        self.running = true;
    }
    pub fn submit(self: *ExecutionQueue, comptime function: anytype, args: anytype) !void {
        try self.queue.push(function, args);
    }

    pub fn pop(self: *ExecutionQueue) !void {
        if (self.queue.queue.items.len == 0 or !self.running) return;
        const task = self.queue.queue.swapRemove(0);
        defer task.deinit_fn(task.args_ptr, self.queue.allocator);
        try task.exec_fn(task.args_ptr);
    }
    
    pub fn deinit(self: *ExecutionQueue) void {
        self.running = false;
        self.queue.queue.deinit(self.queue.allocator);
    }
};