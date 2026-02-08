const std = @import("std");
const ztracy = @import("ztracy");

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

    pub fn popAndExecute(self: *Self) anyerror!void {
        self.mutex.lock();
        if (self.queue.items.len == 0) {
            self.mutex.unlock();
            return;
        }
        const task = self.queue.swapRemove(0);
        self.mutex.unlock();
        defer task.deinit_fn(task.args_ptr, self.allocator);
        try task.exec_fn(task.args_ptr);
    }
};

pub const ExecutionQueue = struct{
    queue: Queue,
    running: bool = true,
    threads: []std.Thread,
    cond: std.Thread.Condition = .{},

    pub fn worker(self: *ExecutionQueue) !void {
        while (self.running) {
            self.queue.mutex.lock();
            
            // Чекаємо, поки з'явиться робота АБО поки двигун не зупинять
            while (self.queue.queue.items.len == 0 and self.running) {
                // Wait відпускає м'ютекс і ставить потік "на паузу"
                self.cond.wait(&self.queue.mutex);
                // Коли потік прокидається, він знову автоматично закриває м'ютекс
            }

            if (!self.running) {
                self.queue.mutex.unlock();
                break;
            }

            // Забираємо задачу
            const task = self.queue.queue.swapRemove(0);
            self.queue.mutex.unlock();

            // Виконуємо
            defer task.deinit_fn(task.args_ptr, self.queue.allocator);
            task.exec_fn(task.args_ptr) catch |err| {
                std.log.err("Task failed: {}", .{err});
            };
        }
    }

    pub fn init(self: *ExecutionQueue, threads_slice: []std.Thread, allocator: std.mem.Allocator) !void {
        self.queue = try Queue.init(allocator);
        self.threads = threads_slice;
        self.running = true;

        for (self.threads) |*thread| {
            // Передаємо вказівник на стабільну глобальну чергу
            thread.* = try std.Thread.spawn(.{ .allocator = allocator }, worker, .{self});
        }
    }
    pub fn submit(self: *ExecutionQueue, comptime function: anytype, args: anytype) !void {
        try self.queue.push(function, args);
        // Будимо ОДИН вільний потік, щоб він забрав задачу
        self.cond.signal(); 
    }
    
    pub fn deinit(self: *ExecutionQueue) void {
        self.running = false;
        // Будимо УСІ потоки, щоб вони побачили running = false і завершилися
        self.cond.broadcast(); 
        for (self.threads) |thread| thread.join();
    }
};