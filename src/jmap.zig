const std = @import("std");

pub const Account = @import("Account.zig");
pub const Client = @import("Client.zig");
pub const Request = @import("Request.zig");
pub const Response = @import("Response.zig");
pub const Session = @import("Session.zig");

pub const capability = @import("capability.zig");
pub const method = @import("method.zig");

pub const mail = @import("mail.zig");

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
