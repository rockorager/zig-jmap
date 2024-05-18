const std = @import("std");
const json = std.json;
const jmap = @import("jmap.zig");
const capability = @import("capability.zig");

const Account = @This();

name: []const u8,
is_personal: bool,
is_read_only: bool,
capabilities: struct {
    mail: ?capability.Mail,
},

pub fn jsonParse(
    allocator: std.mem.Allocator,
    source: anytype,
    options: json.ParseOptions,
) !Account {
    const value = try json.parseFromTokenSource(json.Value, allocator, source, options);
    return jsonParseFromValue(allocator, value.value, options);
}

pub fn jsonParseFromValue(
    allocator: std.mem.Allocator,
    source: json.Value,
    options: json.ParseOptions,
) !Account {
    const root = switch (source) {
        .object => |obj| obj,
        else => return error.UnexpectedToken,
    };
    const name = root.get("name") orelse return error.MissingField;
    const is_personal = root.get("isPersonal") orelse return error.MissingField;
    const is_read_only = root.get("isReadOnly") orelse return error.MissingField;
    const capability_map = root.get("accountCapabilities") orelse return error.MissingField;

    const mail_capability: ?capability.Mail = if (capability_map.object.get(capability.mail)) |mail| blk: {
        const parsed = try json.parseFromValue(capability.Mail, allocator, mail, options);
        break :blk parsed.value;
    } else null;

    return .{
        .name = name.string,
        .is_personal = is_personal.bool,
        .is_read_only = is_read_only.bool,
        .capabilities = .{
            .mail = mail_capability,
        },
    };
}
