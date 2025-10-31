// -----------------------------------------------------------------
/// Usable imports and configuration

const std = @import("std");
const config = @import("config.zig");
const dependencies = @import("dependencies.zig");
// -----------------------------------------------------------------

pub fn build(Build: *std.Build) !void {
  // -----------------------------------------------------------------
  // Configurations imported and compilation arguments
  const version = try std.SemanticVersion.parse(config.version);
  dependencies.Dependencies = std.StringHashMap(dependencies.Dependency).init(Build.allocator);
  defer dependencies.Dependencies.deinit();
  try dependencies.init();

  const OptimizeOption = Build.standardOptimizeOption(.{.preferred_optimize_mode = .ReleaseFast});
  const TargetOption = Build.standardTargetOptions(.{});

  const plugins = Build.dependency("plugins", .{
    .dependenies = dependencies,
    .target = TargetOption,
    .optimize = OptimizeOption
  });

  // -----------------------------------------------------------------

  const Core = Build.addModule("Core", .{
    .root_source_file = .{ .cwd_relative = "Engine/Core/main.zig" },
    .target = TargetOption,
    .optimize = OptimizeOption
  });

  const GUI = Build.addExecutable(.{
    .name = "HEAT",
    .version = version,
    .root_module = Build.addModule("Editor", .{
      .root_source_file = .{ .cwd_relative = "Engine/GUI/main.zig" },
      .target = TargetOption,
      .optimize = OptimizeOption
    })
  });
  GUI.root_module.addImport("Core", Core);
  
  const UserExecutable = Build.addLibrary(.{
    .linkage = .static,
    .name = "Executable",
    .version = version,
    .root_module = Build.addModule("Executable", .{
      .root_source_file = .{ .cwd_relative = "Engine/UserExecutable/main.zig" },
      .target = TargetOption,
      .optimize = OptimizeOption
    })
  });
  UserExecutable.root_module.addImport("Core", Core);

  const InstallExeOption = std.Build.Step.InstallArtifact.Options{
    .dest_dir = .{ .override = .{ .custom = try std.fmt.allocPrint(Build.allocator, "../{s}", .{config.EditorOutputDir}) } },
    .pdb_dir = .disabled,
  };

  const InstallLibOption = std.Build.Step.InstallArtifact.Options{
    .dest_dir = .{ .override = .{ .custom = try std.fmt.allocPrint(Build.allocator, "../{s}", .{config.ExecutableOutputDir}) } },
    .pdb_dir = .disabled,
  };

  const InstallGUI = Build.addInstallArtifact(GUI, InstallExeOption);
  const InstallLib = Build.addInstallArtifact(UserExecutable, InstallLibOption);

  Build.default_step.dependOn(&InstallGUI.step);
  Build.default_step.dependOn(&InstallLib.step);
}