const std = @import("std");
const assert = std.debug.assert;
const capability = @import("capability.zig");
const json = std.json;
const jmap = @import("jmap.zig");

const Account = @import("Account.zig");
const Core = capability.Core;

const Id = jmap.Id;
const IdMap = json.ArrayHashMap(Id);
const AccountMap = json.ArrayHashMap(Account);

const Session = @This();

capabilities: struct {
    core: Core,
},
primary_accounts: IdMap,
accounts: AccountMap,
username: []const u8,
api_url: []const u8,
download_url: []const u8,
upload_url: []const u8,
event_source_url: []const u8,
state: []const u8,

pub fn jsonParse(
    allocator: std.mem.Allocator,
    source: anytype,
    options: json.ParseOptions,
) !Session {
    const value = try json.parseFromTokenSource(json.Value, allocator, source, options);
    return jsonParseFromValue(allocator, value.value, options);
}

pub fn jsonParseFromValue(
    allocator: std.mem.Allocator,
    source: json.Value,
    options: json.ParseOptions,
) !Session {
    const root = switch (source) {
        .object => |obj| obj,
        else => return error.UnexpectedToken,
    };
    const capabilities_map = root.get("capabilities") orelse return error.MissingField;
    const primary_accounts_map = root.get("primaryAccounts") orelse return error.MissingField;
    const accounts_map = root.get("accounts") orelse return error.MissingField;

    const capabilities = try json.parseFromValue(json.ArrayHashMap(json.Value), allocator, capabilities_map, options);
    const core_value = capabilities.value.map.get(capability.core) orelse return error.MissingField;
    const core = try json.parseFromValue(Core, allocator, core_value, options);

    const primary_accounts = try json.parseFromValue(IdMap, allocator, primary_accounts_map, options);
    const accounts = try json.parseFromValue(AccountMap, allocator, accounts_map, options);

    const username = root.get("username") orelse return error.MissingField;
    const api_url = root.get("apiUrl") orelse return error.MissingField;
    const download_url = root.get("downloadUrl") orelse return error.MissingField;
    const upload_url = root.get("uploadUrl") orelse return error.MissingField;
    const event_source_url = root.get("eventSourceUrl") orelse return error.MissingField;
    const state = root.get("state") orelse return error.MissingField;
    return .{
        .capabilities = .{
            .core = core.value,
        },
        .primary_accounts = primary_accounts.value,
        .accounts = accounts.value,
        .username = username.string,
        .api_url = api_url.string,
        .download_url = download_url.string,
        .upload_url = upload_url.string,
        .event_source_url = event_source_url.string,
        .state = state.string,
    };
}

pub fn jsonStringify(self: *Session, stream: anytype) !void {
    try stream.write(.{
        .capabilities = self.capabilities,
        .accounts = self.accounts,
        .primaryAccounts = self.primary_accounts,
        .username = self.username,
        .apiUrl = self.api_url,
        .downloadUrl = self.download_url,
        .eventSourceUrl = self.event_source_url,
        .state = self.state,
    });
}

test "Session: parse" {
    const session_json =
        \\{
        \\"capabilities": {
        \\    "urn:ietf:params:jmap:core": {
        \\    "maxSizeUpload": 50000000,
        \\    "maxConcurrentUpload": 8,
        \\    "maxSizeRequest": 10000000,
        \\    "maxConcurrentRequests": 8,
        \\    "maxCallsInRequest": 32,
        \\    "maxObjectsInGet": 256,
        \\    "maxObjectsInSet": 128,
        \\    "collationAlgorithms": [
        \\        "i;ascii-numeric",
        \\        "i;ascii-casemap",
        \\        "i;unicode-casemap"
        \\    ]
        \\    },
        \\    "test:jmap:capability": {
        \\    "testValue": 500
        \\    },
        \\    "urn:ietf:params:jmap:mail": {},
        \\    "urn:ietf:params:jmap:contacts": {},
        \\    "https://example.com/apis/foobar": {
        \\    "maxFoosFinangled": 42
        \\    }
        \\},
        \\"accounts": {
        \\    "A13824": {
        \\    "name": "john@example.com",
        \\    "isPersonal": true,
        \\    "isReadOnly": false,
        \\    "accountCapabilities": {
        \\        "urn:ietf:params:jmap:contacts": {
        \\        }
        \\    }
        \\    },
        \\    "A97813": {
        \\    "name": "jane@example.com",
        \\    "isPersonal": false,
        \\    "isReadOnly": true,
        \\    "accountCapabilities": {
        \\    }
        \\    }
        \\},
        \\"primaryAccounts": {
        \\    "urn:ietf:params:jmap:mail": "A13824",
        \\    "urn:ietf:params:jmap:contacts": "A13824"
        \\},
        \\"username": "john@example.com",
        \\"apiUrl": "https://jmap.example.com/api/",
        \\"downloadUrl": "https://jmap.example.com/download/{accountId}/{blobId}/{name}?accept={type}",
        \\"uploadUrl": "https://jmap.example.com/upload/{accountId}/",
        \\"eventSourceUrl": "https://jmap.example.com/eventsource/?types={types}&closeafter={closeafter}&ping={ping}",
        \\"state": "75128aab4b1b"
        \\}
    ;
    const parsed = try json.parseFromSlice(Session, std.testing.allocator, session_json, .{});
    defer parsed.deinit();
}
