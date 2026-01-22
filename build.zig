//! Build script for the Engine
//! This file is executed by the Zig build system when running `zig build`
//! in this directory.
//! 
//! General overview of this build script:
//! - First we get top-level fields like allocator etc.
//! - Then we load config profile which specifies how to build everything
//! - Next Command-Line Interface is setup
//! - Futher going we setup Engine module and ArrayLists for Modules and Compiles
//!   to quickly build everything with a loop
//! - After that we have a platform wrapper layer
//! - (not implemented now)Then dependencies are loaded
//! - Then we process all modules and compiles to build them
//!  
//! Info on how to use this Zig build system:
//! - General build system info: https://ziglang.org/documentation/master/#Build-System
//! - This engine uses "mach" game engine as it's core and expands upon it.
//! - File structure: 
//! -   src: Core of the engine. It's structure is:
//!     - Engine.zig: Root importable module of the engine.
//!     - Core: Full logic of the engine separated into files:
//!       - Platform: Platform specific code.
//!       - Interpreter: Scripting language interpreter.
//!       - 
//!
//! -   build.zig.zon: ZON file, which is package configuration for the 
//!                    Zig package manager.
//! -   config.zig: configuration variables for the build script and project.
//! 
//! - This engine is modular so it's functionality can be extended by adding modules,
//!   to do so use build/Dependencies.zig file, look into it for more info. 
//! - Command-line options: ...
//! 
//! 
//! 
// ------------------------------------------------------------------------------------
// This section is for imports and top-level fields.
// ------------------------------------------------------------------------------------
const std = @import("std");
const config = @import("config.zig");
var Engine: *std.Build.Module = undefined;

// ------------------------------------------------------------------------------------
// This section is for main build function.
// ------------------------------------------------------------------------------------
pub fn build(b: *std.Build) !void {
  // ----------------------------------------------------------------------------------
  // Top-level in-build fields.
  // They are commonly used in this build so they are abstracted here for convenience.
  // ----------------------------------------------------------------------------------
  const allocator = b.allocator;
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{.preferred_optimize_mode = config.Optimize});


  // Load configuration profile(if selected)
  if(config.Profile) |profile| profile();
  b.install_prefix = config.OutputDir;
  // So we concat path because when specifying exe_dir it will automatically override install prefix
  // and set it to current directory.
  // &.{} is a trick to make a quick constant zig slice
  b.exe_dir = try std.mem.concat(allocator, u8,  &.{try std.mem.concat(allocator, u8, &.{config.OutputDir, "/"}), config.BinDir});
  b.lib_dir = try std.mem.concat(allocator, u8, &.{try std.mem.concat(allocator, u8, &.{config.OutputDir, "/"}), config.LibDir});
  
  
  // ----------------------------------------------------------------------------------
  // CLI(Command-Line Interface) setup with config.
  // It loads arguments from config or from command-line if provided
  // ----------------------------------------------------------------------------------
  var MultiPlatform = b.option(bool, "MultiPlatform", "This option allows build script to compile engine for each *available* target");
  var Docs = b.option(bool, "Docs", "Specifies if documentation files should be generated");
  var ztracy_option = b.option(bool, "Tracy", "Specifies if ztracy is enabled");
  // To use 'step' call zig build "step's name",
  // here use zig build test
  const test_step = b.step("test", "Run tests");

  if (MultiPlatform == null) MultiPlatform = config.MultiPlatform;
  if (Docs == null) Docs = config.GenerateDocs;
  if (ztracy_option == null) ztracy_option = config.EnableZtracy;

  // ...

  // ----------------------------------------------------------------------------------
  // Section where engine is defined as module and executable with it is made
  // ----------------------------------------------------------------------------------
  // List of modules allows this build script to easily manipulate them for different purposes
  // like docs generation, tests, etc.
  var Modules: std.ArrayList(*std.Build.Module) = .empty;
  defer Modules.deinit(allocator);

  // List of compile steps allows build script to group them up for different purposes,
  // also for docs generation, tests, etc.
  var CompileFiles: std.ArrayList(*std.Build.Step.Compile) = .empty;
  defer CompileFiles.deinit(allocator);

  Engine = b.addModule("Engine", .{
    .root_source_file = b.path("src/Engine.zig"),
    .target = target,
    .optimize = optimize,
  });
  try Modules.append(allocator, Engine);


  // ----------------------------------------------------------------------------------
  // Platform wrapper
  // ----------------------------------------------------------------------------------
  const Platform_Header = b.addModule("Platform_Header", .{
    .root_source_file = .{ .cwd_relative = "src/Core/Platform.zig" },
    .target = target,
    .optimize = optimize
  });
  try Modules.append(allocator, Platform_Header);
  const Platform = b.addModule("Platform", .{
    .target = target,
    .optimize = optimize,
    // Importing Platform Header
    .imports = &.{.{.name = "Platform", .module = Platform_Header}, .{.name = "Engine", .module = Engine}},
    // Selecting a platform wrapper file according to current target
    .root_source_file = .{ .cwd_relative = switch (target.result.os.tag) {
      else => "src/Core/Platform/std_platform.zig"
    }},
  });
  try Modules.append(allocator, Platform);
  Engine.addImport("Platform", Platform);


  // ----------------------------------------------------------------------------------
  // Get all dependencies
  // ----------------------------------------------------------------------------------
  //const ztracy = b.dependency("ztracy", .{
  //  .enable_ztracy = ztracy_option,
  //  .enable_fibers = ztracy_option,
  //});
  //Engine.addImport("ztracy", ztracy.module("root"));
  //Engine.linkLibrary(ztracy.artifact("tracy"));

  if (config.BuildExamples) {
    try CompileFiles.append(allocator, addExecutable(b, .{
      .name = "SimpleIO",
      .user_app = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "Examples/SimpleIO.zig" },
        .target = target,
        .optimize = optimize,
        .imports = &.{.{.name = "Engine", .module = Engine}}
      }),
      .target = target,
      .optimize = optimize
    }));
    
  }

  // ----------------------------------------------------------------------------------
  // Setup all modules 
  // ----------------------------------------------------------------------------------
  for (Modules.items) |Module| {
    // This code adds tests of the modules
    const mod_tests = b.addTest(.{
      .root_module = Module,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    test_step.dependOn(&run_mod_tests.step);
  }


  // ----------------------------------------------------------------------------------
  // Compile everything, add it's docs and tests
  // ----------------------------------------------------------------------------------
  for (CompileFiles.items) |CompileFile| {
    // Compile and build the artifact
    b.installArtifact(CompileFile);
    // If needed, generate docs
    if (Docs.?) {
      const install_docs = b.addInstallDirectory(.{
        .source_dir = CompileFile.getEmittedDocs(),
        // It installes it into zig-out/Docs, we pass ../ to install it into just Docs
        .install_dir = .{ .custom = "../" },
        .install_subdir = "Docs"
      });
      
      b.default_step.dependOn(&install_docs.step);
    }
    // Make tests for this artifact
    const compile = b.addTest(.{
      .root_module = CompileFile.root_module,
    });
    const compile_tests = b.addRunArtifact(compile);
    test_step.dependOn(&compile_tests.step);
  }

}


// ----------------------------------------------------------------------------------
// User functions section
// ----------------------------------------------------------------------------------
pub fn addExecutable(b: *std.Build, Options: ExecutableOptions) *std.Build.Step.Compile {
  return b.addExecutable(.{
    .name = Options.name,
    .root_module = b.addModule(b.fmt("{s}-entrypoint", .{Options.name}), .{
      .root_source_file = .{ .cwd_relative = "src/Entrypoint.zig" },
      .target = Options.target,
      .optimize = Options.optimize,
      .imports = &.{
        .{.name = "App", .module = Options.user_app},
        .{.name = "Engine", .module = Engine}}
    })
  });
}

pub const ExecutableOptions = struct {
  name: []const u8,
  user_app: *std.Build.Module,
  target: std.Build.ResolvedTarget,
  optimize: std.builtin.OptimizeMode
};