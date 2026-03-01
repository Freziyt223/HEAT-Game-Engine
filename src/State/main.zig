// =========================================================================================
// Imports
const std = @import("std");
const IO = @import("IO");
const Renderer = @import("Renderer");
const Thread = @import("Thread");

pub var conf = @import("conf.zig");

// =========================================================================================
// Main program's state
var state: std.atomic.Value(bool) = .init(true);
pub var Mutex = std.Thread.Mutex{};
// pub var BusyThreads: usize = 1; // Main thread is always busy

pub var Running: bool = true;
pub var UsedMemory: usize = 0;
pub var MemoryCapacity: usize = 0;
pub var PeakMemoryUsage: usize = 0;
pub var Windows: std.ArrayList(Renderer.Window) = .empty;

pub var MultiThreading: bool = true;