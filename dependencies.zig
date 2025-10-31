//! This is where dependencies are managed, they are first parsed in build.zig.
//! Then they go to Plugins/build.zig where they are downloaded and activated

// ----------------------------------------------------------------------------
// Imports
const std = @import("std");

// ----------------------------------------------------------------------------
// User zone, enter your code here

pub var DearImGui: Dependency = .{
  .name = "ImGUI",
  .version = "1.92.4-docking",
  .required = true,
  .path = "https://github.com/ocornut/imgui/releases/tag/v${version}",
};
pub fn init() !void {
  try DearImGui.registrate();
}

// ----------------------------------------------------------------------------
// Declarations zone, here is where usable structs and functions live,
// you can edit it if you want to, but this is mostly for use-only.

/// List of all dependencies
pub var Dependencies: std.StringHashMap(Dependency) = undefined;
/// Template struct for the dependencies
pub const Dependency = struct{
  name: []const u8,
  version: [*:0]const u8,
  required: bool,

  path: []const u8,
  
  pub fn registrate(self: Dependency) !void {
    try Dependencies.put(self.name, self);
  }
  pub fn remove(self: Dependency) void {
    Dependencies.remove(self.name);
  }
};