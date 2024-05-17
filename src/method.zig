const std = @import("std");
const assert = std.debug.assert;
const jmap = @import("jmap.zig");
const json = std.json;

const Mailbox = @import("mail/Mailbox.zig");

pub const Methods = enum {
    @"Mailbox/get",
};

pub const MethodCall = union(Methods) {
    @"Mailbox/get": Mailbox.Get.Request,

    pub fn jsonStringify(self: MethodCall, stream: anytype) !void {
        const args = switch (self) {
            inline else => |call| call,
        };
        const id = switch (self) {
            inline else => |call| call.call_id,
        };
        try stream.write(
            .{
                @tagName(self),
                args,
                id,
            },
        );
    }
};

pub const MethodResponse = union(Methods) {
    @"Mailbox/get": Mailbox.Get.Response,

    pub fn jsonParse(
        allocator: std.mem.Allocator,
        source: anytype,
        options: json.ParseOptions,
    ) !MethodResponse {
        const value = try json.parseFromTokenSource(json.Value, allocator, source, options);
        return jsonParseFromValue(allocator, value.value, options);
    }

    pub fn jsonParseFromValue(
        allocator: std.mem.Allocator,
        source: json.Value,
        _: json.ParseOptions,
    ) !MethodResponse {
        const root = switch (source) {
            .array => |arr| arr,
            else => return error.UnexpectedToken,
        };
        assert(root.items.len == 3);
        const method_name = root.items[0].string;
        const args = root.items[1];
        const call_id = root.items[2].string;

        const method = std.meta.stringToEnum(Methods, method_name) orelse return error.UnexpectedToken;
        switch (method) {
            .@"Mailbox/get" => {
                const parsed = try json.parseFromValue(Mailbox.Get.Response, allocator, args, .{ .ignore_unknown_fields = true });
                var response = parsed.value;
                response.call_id = call_id;
                return .{
                    .@"Mailbox/get" = response,
                };
            },
        }
    }
};
