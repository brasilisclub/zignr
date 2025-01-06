const std = @import("std");
const print = std.io.getStdOut().writer();
const request = @import("api.zig").request;

// get language .gitgnore command
pub fn getGitignoreContent(args: [][:0]u8, languages: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const body = try request(allocator, args, languages);
    defer allocator.free(body);

    try print.print("{s}\n", .{body});
}

// list command
pub fn listAvailableLanguages(args: [][:0]u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const body = try request(allocator, args, "list");
    defer allocator.free(body);

    try print.print("{s}\n", .{body});
}
