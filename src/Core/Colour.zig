//!
//! 
// ----------------------------------------------------------------------------------
// Imports and top-level fields
// ----------------------------------------------------------------------------------
const std = @import("std");
const Platform = @import("Platform");
const IO = @import("IO.zig");


// ----------------------------------------------------------------------------------
// Genral fields for working with colours
// ----------------------------------------------------------------------------------
pub const Colour = extern union {
    rgba: extern struct {r: u8, g: u8, b: u8, a: u8},
    Hex: u32,
    indexes: [4]u8
};