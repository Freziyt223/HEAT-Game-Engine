// =========================================================================================
// Imports
const std = @import("std");


// =========================================================================================
// Main program's state
pub var windows: std.ArrayList(u8) = .empty; // For now it's u8 until i assign actual window type
pub var Running: bool = true;