const std = @import("std");
const http = std.http;
const json = std.json;
const assert = std.debug.assert;

const method = @import("method.zig");
const MethodResponse = method.MethodResponse;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Session = @import("Session.zig");

const Client = @This();

allocator: std.mem.Allocator,
/// arena is used for allocating the session object
arena: std.heap.ArenaAllocator,
client: http.Client,
uri: std.Uri,
auth_header: http.Header,
session: ?Session,
api_uri: ?std.Uri,

/// Caller owns the memory of host, which must outlive the client. The token
/// will be owned by the client
pub fn init(allocator: std.mem.Allocator, host: []const u8, token: []const u8) !Client {
    return .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .client = .{ .allocator = allocator },
        .uri = try std.Uri.parse(host),
        .auth_header = .{
            .name = "Authorization",
            .value = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token}),
        },
        .session = null,
        .api_uri = null,
    };
}

pub fn deinit(self: *Client) void {
    self.allocator.free(self.auth_header.value);
    self.client.deinit();
    self.arena.deinit();
}

pub fn do(self: *Client, req: Request) !Response {
    if (self.api_uri == null) try self.getSession();
    assert(self.api_uri != null); // api_uri not set during getSession

    const bytes = try json.stringifyAlloc(self.allocator, req, .{});
    defer self.allocator.free(bytes);
    var response = std.ArrayList(u8).init(self.allocator);
    defer response.deinit();
    const status = try self.client.fetch(.{
        .headers = .{
            .content_type = .{ .override = "application/json" },
        },
        .location = .{ .uri = self.api_uri.? },
        .extra_headers = &.{self.auth_header},
        .payload = bytes,
        .response_storage = .{ .dynamic = &response },
    });
    switch (status.status) {
        .ok => {},
        else => return error.BadHttpRequest,
    }
    const parsed = try json.parseFromSlice(Response, self.allocator, response.items, .{});
    defer parsed.deinit();
    return parsed.value;
}

/// connect to the endpoint and obtain the Session object
pub fn getSession(self: *Client) !void {
    _ = self.arena.reset(.retain_capacity);
    var headers: [4096]u8 = undefined;
    var req = try self.client.open(.GET, self.uri, .{
        .server_header_buffer = &headers,
        .extra_headers = &.{self.auth_header},
        .keep_alive = false,
    });
    defer req.deinit();
    try req.send();
    try req.wait();

    const body = try req.reader().readAllAlloc(self.allocator, 8192);
    defer self.allocator.free(body);
    const parsed = try json.parseFromSliceLeaky(Session, self.arena.allocator(), body, .{
        .allocate = .alloc_always,
    });
    self.session = parsed;
    self.api_uri = try std.Uri.parse(self.session.?.api_url);
}
