// =========================================================================================
// Imports and top-level fields
const std = @import("std");
pub const config = @import("config.zig");


// Depdendencies
var ztracy_mod: *std.Build.Module = undefined;
var ztracy_art: *std.Build.Step.Compile = undefined;
var zigzag: *std.Build.Module = undefined;
var zglfw_mod: *std.Build.Module = undefined;
var zglfw_art: *std.Build.Step.Compile = undefined;
var vulkan_zig: ?*std.Build.Module = undefined;
// Options
var options_module: *std.Build.Module = undefined;

// =========================================================================================
// Main build entrypoint
pub fn build(b: *std.Build) void {
    // =====================================================================================
    // Input, config and top-level fields
    config.profile();
    const target = b.standardTargetOptions(if (config.target) |Target| .{.default_target = Target.query} else .{});
    const Options = .{
        .optimize = b.option(std.builtin.OptimizeMode, "optimize", "Specify optimization level") orelse config.optimize,
        .enable_ztracy = b.option(bool, "enable_ztracy", "Specify if engine should come with tracy profiler") orelse config.Enable.ztracy,
        .enable_zigzag = b.option(bool, "enable_zigzag", "Specify if engine should come with zigzag profiler") orelse config.Enable.zigzag,
        .enable_vulkan = b.option(bool, "enable_vulkan", "Specify if engine should come with vulkan renderer") orelse config.Enable.vulkan,
    };

    const options_step = b.addOptions();
    inline for (std.meta.fields(@TypeOf(Options))) |field| {
        options_step.addOption(field.type, field.name, @field(Options, field.name));
    }

    options_module = options_step.createModule();
    // =====================================================================================
    // Dependencies
    const ztracy_dep = b.dependency("ztracy", .{
        .target = target,
        .optimize = Options.optimize,
        .enable_ztracy = Options.enable_ztracy,
    });
    
    ztracy_mod = ztracy_dep.module("root");
    //ztracy_mod.strip = true;
    ztracy_art = ztracy_dep.artifact("tracy");
    //ztracy_art.root_module.strip = true;

    zigzag = b.dependency("zigzag", .{
        .target = target,
        .optimize = Options.optimize
    }).module("zigzag");

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = Options.optimize,
        .import_vulkan = Options.enable_vulkan,
    });
    zglfw_mod = zglfw.module("root");
    zglfw_art = zglfw.artifact("glfw");

    
    vulkan_zig = if (Options.enable_vulkan) b.dependency("vulkan_zig", .{
        .target = target,
        .optimize = Options.optimize,
        .registry = b.dependency("vulkan_headers", .{}).path("registry/vk.xml")
    }).module("vulkan-zig") else null;
   if (vulkan_zig) |vulkan| zglfw_mod.addImport("vulkan", vulkan);

    // =====================================================================================
    // Engine separated into modules
    const types = b.addModule("types", .{
        .root_source_file = b.path("src/types.zig"),
        .target = target,
        .optimize = Options.optimize,
    });

    
    const State = b.addModule("State", .{
        .root_source_file = b.path("src/State/main.zig"),
        .target = target,
        .optimize = Options.optimize,
        //.strip = true,
    });

    const TrackingAllocator = b.addModule("TrackingAllocator", .{
        .root_source_file = b.path("src/TrackingAllocator.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "ztracy", .module = ztracy_mod},
            .{.name = "State", .module = State},
        },
        //.strip = true,
    });

    const IO = b.addModule("IO", .{
        .root_source_file = b.path("src/IO/main.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "buildOptions", .module = options_module},
        },
        //.strip = true,
    });


    const Thread = b.addModule("Thread", .{
        .root_source_file = b.path("src/Thread/main.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "ztracy", .module = ztracy_mod},
            .{.name = "State", .module = State},
        },
        //.strip = true
    });

    const Interface = b.createModule(.{
        .root_source_file = b.path("src/Renderer/Interface.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{.{.name = "IO", .module = IO}}
    });

    const Renderer = b.addModule("Renderer", .{
        .root_source_file = b.path("src/Renderer/main.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "ztracy", .module = ztracy_mod},
            .{.name = "zglfw", .module = zglfw_mod},
            .{.name = "types", .module = types},
            .{.name = "Interface", .module = Interface},
            .{.name = "TrackingAllocator", .module = TrackingAllocator},
            .{.name = "IO", .module = IO},
            .{.name = "buildOptions", .module = options_module}
        },
        //.strip = true
    });
    if (target.result.os.tag != .emscripten) Renderer.linkLibrary(zglfw_art);
    if (vulkan_zig) |vulkan| Renderer.addImport("vulkan-zig", vulkan);

    const RendererRoot = b.addModule("RendererRoot", .{
        .root_source_file = b.path("src/Renderer/root.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "Renderer", .module = Renderer},
            .{.name = "Interface", .module = Interface},
        },
        //.strip = true
    });

    const Engine = b.addModule("Engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = Options.optimize,
        .imports = &.{
            .{.name = "IO", .module = IO},
            .{.name = "TrackingAllocator", .module = TrackingAllocator},
            .{.name = "ztracy", .module = ztracy_mod},
            .{.name = "Thread", .module = Thread},
            .{.name = "buildOptions", .module = options_module},
            .{.name = "Renderer", .module = RendererRoot},
            .{.name = "types", .module = types}
        },
        //.strip = true,
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
    const State = engine_builder.modules.get("State").?;
    const Thread = engine_builder.modules.get("Thread").?;
    const Root = engine_builder.modules.get("Engine").?;
    const TrackingAllocator = engine_builder.modules.get("TrackingAllocator").?;
    const Renderer = engine_builder.modules.get("Renderer").?;
    options.user_module.addImport("State", State);

    const Entrypoint = engine_builder.addModule("Entrypoint", .{
        .root_source_file = engine_builder.path("src/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
        .imports = &.{
            .{.name = "User", .module = options.user_module},
            .{.name = "State", .module = State},
            .{.name = "ztracy", .module = ztracy_mod},
            .{.name = "Thread", .module = Thread},
            .{.name = "Root", .module = Root},
            .{.name = "TrackingAllocator", .module = TrackingAllocator},
            .{.name = "buildOptions", .module = options_module},
            .{.name = "Renderer", .module = Renderer},
        },
        //.strip = true,  
    });
    Entrypoint.linkLibrary(ztracy_art);

    const exe = engine_builder.addExecutable(.{
        .name = options.name,
        .root_module = Entrypoint,
    });
    return exe;
}