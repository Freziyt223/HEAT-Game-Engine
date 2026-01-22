//! Build configuration for the Engine project.
//! 
// ------------------------------------------------------------------------------------
// This section is for imports
// ------------------------------------------------------------------------------------
const std = @import("std");


// ------------------------------------------------------------------------------------
// This section is for pre-compilation options
// ------------------------------------------------------------------------------------
pub var OutputDir: []const u8 = "Release";
// All directories are relative to OutputDir.
pub var BinDir: []const u8 = "Bin";
pub var ObjDir: []const u8 = "Obj";
pub var LibDir: []const u8 = "Lib";
/// 'zig build -DOptimize=...' option will override this value if provided.
pub var Optimize: std.builtin.OptimizeMode = .ReleaseFast;


// ------------------------------------------------------------------------------------
// This section is for enabling or disabling features of compilation.
// ------------------------------------------------------------------------------------
/// MultiPlatform means build script will compile engine for many platforms at once
pub var MultiPlatform: bool = false;
pub var EnableTests: bool = true;
pub var GenerateDocs: bool = true;
pub var EnableZtracy: bool = true;

pub var BuildExamples: bool = true;


// ------------------------------------------------------------------------------------
// This section is for different configuration profiles.
// Configuration profile is a function that is executed only once at the start of the build
// and allows user to switch between different build configurations quickly and also 
// execute the code needed to set up each profile.
// You can switch between profiles by calling the corresponding function.
// ------------------------------------------------------------------------------------
pub var Profile: ?*const fn() void  = &Release;

fn Debug() void {
  OutputDir = "Debug";
  Optimize = .Debug;
}

fn Release() void {
  OutputDir = "Release";
  Optimize = .ReleaseFast;
}