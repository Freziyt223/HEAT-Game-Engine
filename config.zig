// =========================================================================================
// Imports
const std = @import("std");


// =========================================================================================
// Build related
pub var target: ?std.Build.ResolvedTarget = null;
pub var optimize: std.builtin.OptimizeMode = .Debug;
pub var install_prefix: []const u8 = "";


// =========================================================================================
// Toggleables
pub var enable_tracy = false;


// =========================================================================================
// Profiles
pub var profile = &default;

fn default() void {

}