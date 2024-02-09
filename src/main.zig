const std = @import("std");
const print = std.io.getStdOut().writer();
const http = std.http;
const is_zig_11 = @import("builtin").zig_version.minor == 11;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: {s} <language>\n", .{args[0]});
        return;
    }

    if (std.mem.eql(u8, args[1], "list")) {
        std.debug.print("Not implemented yet\n", .{});
        return;
    }
    const language = std.mem.sliceTo(args[1], 0);

    var headers = http.Headers{ .allocator = allocator };
    defer headers.deinit();

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();
    var base_url = "https://www.toptal.com/developers/gitignore/api/";
    var url_buffer: [256]u8 = undefined;
    const url_to_request = try std.fmt.bufPrint(&url_buffer, "{s}{s}", .{ base_url, language });

    const uri = try std.Uri.parse(url_to_request);
    var req = if (is_zig_11) blk: {
        var req = try client.request(.GET, uri, headers, .{});
        errdefer req.deinit();

        try req.start();
        break :blk req;
    } else blk: {
        var req = try client.open(.GET, uri, headers, .{});
        errdefer req.deinit();

        try req.send(.{});
        break :blk req;
    };
    defer req.deinit();

    try req.wait();

    if (req.response.status != .ok) {
        std.debug.print("Probably not a valid language, use: '{s} list' to see the available languages\n", .{args[0]});
        return;
    }

    var rdr = req.reader();
    const body = try rdr.readAllAlloc(allocator, 1024 * 1024 * 4);
    defer allocator.free(body);

    try print.print("{s}\n", .{body});
}
