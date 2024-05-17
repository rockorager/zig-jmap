const std = @import("std");
const jmap = @import("../jmap.zig");
const json = std.json;

const Id = jmap.Id;

const Mailbox = @This();

pub const Role = enum {
    all,
    archive,
    drafts,
    flagged,
    important,
    inbox,
    junk,
    sent,
    subscribed,
    trash,
};

id: Id,
name: ?[]const u8,
parent_id: ?Id,
role: ?Role,
sort_order: ?u32,
total_emails: ?u53,
unread_emails: ?u53,
total_threads: ?u53,
unread_threads: ?u53,
my_rights: ?struct {
    read_items: bool,
    add_items: bool,
    remove_items: bool,
    set_seen: bool,
    set_keywords: bool,
    create_child: bool,
    rename: bool,
    delete: bool,
    submit: bool,
} = null,
is_subscribed: ?bool,

pub fn jsonParseFromValue(
    allocator: std.mem.Allocator,
    source: json.Value,
    options: json.ParseOptions,
) !Mailbox {
    const JsonMailbox = struct {
        id: Id,
        name: ?[]const u8 = null,
        parentId: ?Id = null,
        role: ?[]const u8 = null,
        sortOrder: ?u32 = null,
        totalEmails: ?u53 = null,
        unreadEmails: ?u53 = null,
        totalThreads: ?u53 = null,
        unreadThreads: ?u53 = null,
        myRights: ?struct {
            mayReadItems: bool,
            mayAddItems: bool,
            mayRemoveItems: bool,
            maySetSeen: bool,
            maySetKeywords: bool,
            mayCreateChild: bool,
            mayRename: bool,
            mayDelete: bool,
            maySubmit: bool,
        } = null,
        isSubscribed: ?bool = null,
    };
    const parsed = try json.parseFromValue(JsonMailbox, allocator, source, options);
    return .{
        .id = parsed.value.id,
        .name = parsed.value.name,
        .parent_id = parsed.value.parentId,
        .role = if (parsed.value.role) |role| std.meta.stringToEnum(Role, role) else null,
        .sort_order = parsed.value.sortOrder,
        .total_emails = parsed.value.totalEmails,
        .unread_emails = parsed.value.unreadEmails,
        .total_threads = parsed.value.totalThreads,
        .unread_threads = parsed.value.unreadEmails,
        // .my_rights = .{
        //     .read_items = parsed.value.myRights.mayReadItems,
        //     .add_items = parsed.value.myRights.mayAddItems,
        //     .remove_items = parsed.value.myRights.mayRemoveItems,
        //     .set_seen = parsed.value.myRights.maySetSeen,
        //     .set_keywords = parsed.value.myRights.maySetKeywords,
        //     .create_child = parsed.value.myRights.mayCreateChild,
        //     .rename = parsed.value.myRights.mayRename,
        //     .delete = parsed.value.myRights.mayDelete,
        //     .submit = parsed.value.myRights.maySubmit,
        // },
        .my_rights = null,
        .is_subscribed = parsed.value.isSubscribed,
    };
}

pub const Get = struct {
    pub const Request = struct {
        account_id: Id,
        ids: ?[]const Id,
        properties: ?[]const []const u8,
        call_id: []const u8,

        pub fn jsonStringify(self: *const Request, stream: anytype) !void {
            try stream.write(.{
                .accountId = self.account_id,
                .ids = self.ids,
                .properties = self.properties,
            });
        }
    };

    pub const Response = struct {
        account_id: Id,
        state: []const u8,
        list: []Mailbox,
        not_found: []Id,
        call_id: []const u8 = "",

        pub fn jsonParseFromValue(
            allocator: std.mem.Allocator,
            source: json.Value,
            options: json.ParseOptions,
        ) !Response {
            const JsonResponse = struct {
                accountId: Id,
                state: []const u8,
                list: []Mailbox,
                notFound: []Id,
            };
            const parsed = try json.parseFromValue(JsonResponse, allocator, source, options);
            return .{
                .account_id = parsed.value.accountId,
                .state = parsed.value.state,
                .list = parsed.value.list,
                .not_found = parsed.value.notFound,
            };
        }
    };
};
