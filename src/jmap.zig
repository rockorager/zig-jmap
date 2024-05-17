const std = @import("std");

pub const Session = @import("Session.zig");

/// A record identifier assigned by the server. Must be between 1 and 255 bytes
/// and contain only ASCII alphanumerics, '-', or '_'.
pub const Id = []const u8;

test "all" {
    _ = @import("Account.zig");
    _ = @import("Client.zig");
    _ = @import("Request.zig");
    _ = @import("Session.zig");

    _ = @import("capability.zig");
}
