const std = @import("std");
const capability = @import("capability.zig");
const jmap = @import("jmap.zig");
const json = std.json;
const method = @import("method.zig");
const MethodCall = method.MethodCall;

const Id = jmap.Id;
const IdMap = json.ArrayHashMap(Id);

const Request = @This();

using: []const capability.Urn,
method_calls: []const MethodCall,
created_ids: ?IdMap = null,

pub fn jsonStringify(self: *const Request, stream: anytype) !void {
    if (self.created_ids) |ids|
        try stream.write(.{
            .using = self.using,
            .methodCalls = self.method_calls,
            .createdIds = ids,
        })
    else
        try stream.write(.{
            .using = self.using,
            .methodCalls = self.method_calls,
        });
}

test "request: stringify" {
    const Mailbox = @import("mail/Mailbox.zig");

    const allocator = std.testing.allocator;

    const call: Mailbox.Get.Request = .{
        .account_id = "abcd",
        .properties = null,
        .ids = null,
        .call_id = "123",
    };
    const method_call: method.MethodCall = .{ .@"Mailbox/get" = call };
    const request: Request = .{
        .using = &.{ capability.core, capability.mail },
        .method_calls = &.{method_call},
        .created_ids = null,
    };
    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    try json.stringify(request, .{}, out.writer());
    const expected =
        \\{"using":["urn:ietf:params:jmap:core","urn:ietf:params:jmap:mail"],"methodCalls":[["Mailbox/get",{"accountId":"abcd","ids":null,"properties":null},"123"]]}
    ;
    try std.testing.expectEqualStrings(expected, out.items);
}
