const std = @import("std");

pub fn mergeStructTypes(comptime Destination: type, comptime Source: type) type {
    const DestInfo = @typeInfo(Destination);
    const DestDelcs = DestInfo.@"struct".decls;
    const DestFields = DestInfo.@"struct".fields;
    const SourceInfo = @typeInfo(Source);
    const SourceDelcs = SourceInfo.@"struct".decls;
    const SourceFields = SourceInfo.@"struct".fields;
    
    const Type = std.builtin.Type{.@"struct" = .{
        .fields = DestFields ++ SourceFields,
        .decls = DestDelcs ++ SourceDelcs,
        .layout = .auto,
        .is_tuple = false
    }};
    return @Type(Type);
}

pub fn mergeStructs(comptime Type: type, Struct1: anytype, Struct2: Type) void {
    const T = std.meta.Child(@TypeOf(Struct1));
    const fields = comptime std.meta.fieldNames(Type);
    inline for (fields) |field| {
        if (@hasField(T, field) and @FieldType(T, field) == @FieldType(Type, field)) {
            @field(Struct1.*, field) = @field(Struct2, field);
        }
    }
}