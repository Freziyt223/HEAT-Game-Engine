//! Configuration file for main program and build in general, you can edit most of the options here
// Imports
const std = @import("std");

/// Specify version with *major.minor.patch-pre* syntax, see [zig version syntax](https://semver.org/)
pub const version = "0.1.0-alpha";
/// Current directory relative  
/// This is editor which makes it easier to setup project, manage it and run it
pub const EditorOutputDir = "Test";
/// Current directory relative  
/// This is library that compiles with the code into distributable executable
pub const ExecutableOutputDir = "Test";

