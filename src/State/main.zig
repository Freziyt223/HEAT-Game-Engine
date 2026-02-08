// =========================================================================================
// Imports
const std = @import("std");


// =========================================================================================
// Main program's state
pub var windows: std.ArrayList(u8) = .empty; // For now it's u8 until i assign actual window type
pub var Running: bool = true;
pub var tick_speed: u64 = 60; // amount of ticks per second
pub var frame_speed: u64 = 120; // amount of frames per second

