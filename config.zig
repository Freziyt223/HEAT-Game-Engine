// =========================================================================================
// Imports
const std = @import("std");


// =========================================================================================
// Build related
pub var version: std.SemanticVersion = .{.major = 0, .minor = 0, .patch = 1};
pub var target: ?std.Build.ResolvedTarget = null;
pub var optimize: std.builtin.OptimizeMode = .Debug;
pub var install_prefix: []const u8 = "";
pub var singlethreaded: bool = false;


// =========================================================================================
// Toggleables
pub var Enable: struct {
    ztracy: bool = true,
    zigzag: bool = true,
    vulkan: bool = true,
} = .{};


// =========================================================================================
// Profiles
pub var profile = &default;

fn default() void {

}