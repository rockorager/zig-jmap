const std = @import("std");
const json = std.json;

/// Uniform Resource name, ie "urn:ietf:params:jmap:core"
pub const Urn = []const u8;

pub const core: Urn = "urn:ietf:params:jmap:core";
pub const mail: Urn = "urn:ietf:params:jmap:mail";

pub const Core = struct {
    max_size_upload: u53,
    max_concurrent_upload: u53,
    max_size_request: u53,
    max_concurrent_requests: u53,
    max_calls_in_request: u53,
    max_objects_in_get: u53,
    max_objects_in_set: u53,
    collation_algorithms: []const []const u8,

    const JsonCore = struct {
        maxSizeUpload: u53,
        maxConcurrentUpload: u53,
        maxSizeRequest: u53,
        maxConcurrentRequests: u53,
        maxCallsInRequest: u53,
        maxObjectsInGet: u53,
        maxObjectsInSet: u53,
        collationAlgorithms: []const []const u8,
    };

    pub fn jsonParse(
        allocator: std.mem.Allocator,
        source: anytype,
        options: json.ParseOptions,
    ) !Core {
        const parsed = try json.parseFromTokenSource(JsonCore, allocator, source, options);
        return .{
            .max_size_upload = parsed.value.maxSizeUpload,
            .max_concurrent_upload = parsed.value.maxConcurrentUpload,
            .max_size_request = parsed.value.maxSizeRequest,
            .max_concurrent_requests = parsed.value.maxConcurrentRequests,
            .max_calls_in_request = parsed.value.maxCallsInRequest,
            .max_objects_in_get = parsed.value.maxObjectsInGet,
            .max_objects_in_set = parsed.value.maxObjectsInSet,
            .collation_algorithms = parsed.value.collationAlgorithms,
        };
    }

    pub fn jsonParseFromValue(
        allocator: std.mem.Allocator,
        source: json.Value,
        options: json.ParseOptions,
    ) !Core {
        const parsed = try json.parseFromValue(JsonCore, allocator, source, options);
        return .{
            .max_size_upload = parsed.value.maxSizeUpload,
            .max_concurrent_upload = parsed.value.maxConcurrentUpload,
            .max_size_request = parsed.value.maxSizeRequest,
            .max_concurrent_requests = parsed.value.maxConcurrentRequests,
            .max_calls_in_request = parsed.value.maxCallsInRequest,
            .max_objects_in_get = parsed.value.maxObjectsInGet,
            .max_objects_in_set = parsed.value.maxObjectsInSet,
            .collation_algorithms = parsed.value.collationAlgorithms,
        };
    }

    pub fn jsonStringify(self: Core, stream: anytype) !void {
        const json_core: JsonCore = .{
            .maxSizeUpload = self.max_size_upload,
            .maxConcurrentUpload = self.max_concurrent_upload,
            .maxSizeRequest = self.max_size_request,
            .maxConcurrentRequests = self.max_concurrent_requests,
            .maxCallsInRequest = self.max_calls_in_request,
            .maxObjectsInGet = self.max_objects_in_get,
            .maxObjectsInSet = self.max_objects_in_set,
            .collationAlgorithms = self.collation_algorithms,
        };
        try stream.write(json_core);
    }

    test "json: roundtrip" {
        const expected: Core = .{
            .max_size_upload = 50000000,
            .max_concurrent_upload = 8,
            .max_size_request = 10000000,
            .max_concurrent_requests = 8,
            .max_calls_in_request = 32,
            .max_objects_in_get = 256,
            .max_objects_in_set = 128,
            .collation_algorithms = &.{
                "i;ascii-numeric",
                "i;ascii-casemap",
                "i;unicode-casemap",
            },
        };

        const input =
            \\{
            \\  "maxSizeUpload": 50000000,
            \\  "maxConcurrentUpload": 8,
            \\  "maxSizeRequest": 10000000,
            \\  "maxConcurrentRequests": 8,
            \\  "maxCallsInRequest": 32,
            \\  "maxObjectsInGet": 256,
            \\  "maxObjectsInSet": 128,
            \\  "collationAlgorithms": [
            \\    "i;ascii-numeric",
            \\    "i;ascii-casemap",
            \\    "i;unicode-casemap"
            \\  ]
            \\}
        ;
        const allocator = std.testing.allocator;
        const parsed = try json.parseFromSlice(Core, allocator, input, .{});
        defer parsed.deinit();

        try std.testing.expectEqualDeep(expected, parsed.value);

        const out = try json.stringifyAlloc(allocator, parsed.value, .{});
        defer allocator.free(out);

        const rt_parsed = try json.parseFromSlice(Core, allocator, out, .{});
        defer rt_parsed.deinit();
        try std.testing.expectEqualDeep(expected, rt_parsed.value);
    }
};
