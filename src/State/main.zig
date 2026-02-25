// =========================================================================================
// Imports
const std = @import("std");
const IO = @import("IO");
const Renderer = @import("Renderer");

pub var conf = @import("conf.zig");

// =========================================================================================
// Main program's state
pub var Running: bool = true;
pub var Mutex = std.Thread.Mutex{};
// pub var BusyThreads: usize = 1; // Main thread is always busy

pub var UsedMemory: usize = 0;
pub var MemoryCapacity: usize = 0;
pub var PeakMemoryUsage: usize = 0;
pub var Windows: std.ArrayList(Renderer.Window) = .empty;

pub var MultiThreading: bool = true;