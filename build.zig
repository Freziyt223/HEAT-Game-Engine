// =========================================================================================
// Imports
const std = @import("std");
const config = @import("config.zig");


// =========================================================================================
// Main build entrypoint
pub fn build(b: *std.Build) void {
    // =====================================================================================
    // Input, config and top-level fields
    config.profile();

    const target = b.standardTargetOptions(if (config.target) |Target| .{.default_target = Target.query} else .{});
    const optimize = if (b.option(std.builtin.OptimizeMode, "optimize", "Specify optimize mode for engine")) |Optimize| Optimize else config.optimize;
    const enable_tracy = if (b.option(bool, "enable_tracy", "Specify if engine should come with tracy profiler")) |enable| enable else config.enable_tracy;

    // =====================================================================================
    // Dependencies
    const ztracy_dep = b.dependency("ztracy", .{
        .enable_ztracy = enable_tracy,
        .enable_fibers = enable_tracy
    });
    const ztracy_mod = ztracy_dep.module("root");
    ztracy_mod.optimize = optimize;
    ztracy_mod.strip = true;
    const ztracy_art = ztracy_dep.artifact("tracy");


    // =====================================================================================
    // Engine separated into modules
    const TrackingAllocator = b.addModule("TrackingAllocator", .{
        .root_source_file = b.path("src/TrackingAllocator.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{.name = "ztracy", .module = ztracy_mod}},
        .strip = true,
        .no_builtin = true,
    });
    TrackingAllocator.linkLibrary(ztracy_art);

    const IO = b.addModule("IO", .{
        .root_source_file = b.path("src/IO/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
        .no_builtin = true,
    });

    const Engine = b.addModule("Engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{.name = "IO", .module = IO},
            .{.name = "TrackingAllocator", .module = TrackingAllocator}
        },
        .strip = true,
        .no_builtin = true
    });
    IO.addImport("Root", Engine);
}


// =========================================================================================
// User functions
pub const ExecutableOptions = struct {
    name: []const u8,
    user_module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode
};
pub fn addExecutable(engine_builder: *std.Build, options: ExecutableOptions) *std.Build.Step.Compile {
    return engine_builder.addExecutable(.{
        .name = options.name,
        .root_module = engine_builder.addModule("Entrypoint", .{
            .root_source_file = engine_builder.path("src/main.zig"),
            .target = options.target,
            .optimize = options.optimize,
            .imports = &.{.{.name = "User", .module = options.user_module}}
        }),
    });
}