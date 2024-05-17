const std = @import("std");
const jmap = @import("jmap.zig");
const json = std.json;
const method = @import("method.zig");

const MethodResponse = method.MethodResponse;
const Response = @This();

const Id = jmap.Id;
const IdMap = json.ArrayHashMap(Id);

method_responses: []MethodResponse,
session_state: []const u8,
created_ids: ?IdMap = null,

pub fn jsonParse(
    allocator: std.mem.Allocator,
    source: anytype,
    options: json.ParseOptions,
) !Response {
    const value = try json.parseFromTokenSource(json.Value, allocator, source, options);
    return jsonParseFromValue(allocator, value.value, options);
}

pub fn jsonParseFromValue(
    allocator: std.mem.Allocator,
    source: json.Value,
    options: json.ParseOptions,
) !Response {
    const root = switch (source) {
        .object => |obj| obj,
        else => return error.UnexpectedToken,
    };
    const method_responses_value = root.get("methodResponses") orelse return error.MissingField;
    const method_responses = try json.parseFromValue([]MethodResponse, allocator, method_responses_value, options);

    const session_state = root.get("sessionState") orelse return error.MissingField;

    const created_ids_value = root.get("createdIds");
    const created_ids: ?IdMap = if (created_ids_value) |val| blk: {
        const parsed = try json.parseFromValue(IdMap, allocator, val, options);
        break :blk parsed.value;
    } else null;

    return .{
        .method_responses = method_responses.value,
        .session_state = session_state.string,
        .created_ids = created_ids,
    };
}
