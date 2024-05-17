const std = @import("std");
const json = std.json;
const jmap = @import("jmap.zig");

const Account = @This();

name: []const u8,
is_personal: bool,
is_read_only: bool,
// TODO: capabilities
// capabilities: struct {},

pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: json.ParseOptions) !Account {
    const value = try json.parseFromTokenSource(json.Value, allocator, source, options);
    return jsonParseFromValue(allocator, value.value, options);
}

pub fn jsonParseFromValue(_: std.mem.Allocator, source: json.Value, _: json.ParseOptions) !Account {
    const root = switch (source) {
        .object => |obj| obj,
        else => return error.UnexpectedToken,
    };
    const name = root.get("name") orelse return error.MissingField;
    const is_personal = root.get("isPersonal") orelse return error.MissingField;
    const is_read_only = root.get("isReadOnly") orelse return error.MissingField;

    return .{
        .name = name.string,
        .is_personal = is_personal.bool,
        .is_read_only = is_read_only.bool,
    };
}
