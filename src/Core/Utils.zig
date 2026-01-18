//!
//! 
// ----------------------------------------------------------------------------------
// Imports
// ----------------------------------------------------------------------------------
const std = @import("std");


// ----------------------------------------------------------------------------------
// Structs section
// ----------------------------------------------------------------------------------
pub fn merge(comptime a: type, comptime b: type) type {
    return @Type(.{ .Struct = .{
        .layout = .auto,
        .fields = mergeFields(a, b),
        .is_tuple = false,
        .decls = &.{},
    } });
}

fn mergeFields(comptime a: type, comptime b: type) []const std.builtin.Type.StructField {
  const a_fields = @typeInfo(a).Struct.fields;
    const b_fields = @typeInfo(b).Struct.fields;

    var r_fields: [a_fields.len + b_fields.len]std.builtin.Type.StructField = undefined;
    var r_fields_len = 0;

    inline for (b_fields) |field| {
        var found = false;
        inline for (a_fields) |a_field| {
            if (std.mem.eql(u8, a_field.name, field.name)) {

                if (@TypeOf(a_field.type) != @TypeOf(field.type)) {
                    @compileError("Field " ++ field.name ++ " has different types in " ++ @typeName(a) ++ " and " ++ @typeName(b));
                }

                found = true;
                var original_field = a_field;
                original_field.type = @Type(.{ .Struct = .{
                    .layout = .auto,
                    .fields = mergeFields(a_field.type, field.type),
                    .is_tuple = false,
                    .decls = &.{},
                }});
                r_fields[r_fields_len] = original_field;
                r_fields_len += 1;
                break;
            }
        }
        if (!found) {
            r_fields[r_fields_len] = field;
            r_fields_len += 1;
        }
    }

    inline for (a_fields) |a_field| {
        var found = false;
        inline for (r_fields[0..r_fields_len]) |field| {
            if (std.mem.eql(u8, field.name, a_field.name)) {
                found = true;
                break;
            }
        }
        if (!found) {
            r_fields[r_fields_len] = a_field;
            r_fields_len += 1;
        }
    }

    return r_fields[0..r_fields_len];
}