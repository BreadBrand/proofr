const std = @import("std");
const httpz = @import("httpz");
const parser = @import("./parser.zig");
const types = @import("./types.zig");

pub fn parse(req: *httpz.Request, res: *httpz.Response) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const body = req.body() orelse {
        res.status = 400;
        try res.json(.{ .parseErrors = &.{"INPUT_EMPTY"} }, .{});
        return;
    };

    if (body.len == 0) {
        res.status = 400;
        try res.json(.{ .parseErrors = &.{"INPUT_EMPTY"} }, .{});
        return;
    }

    if (try std.unicode.utf8CountCodepoints(body) > 10000) {
        res.status = 400;
        try res.json(.{ .parseErrors = &.{"INPUT_TOO_LARGE"} }, .{});
        return;
    }

    const parsed_recipe = parser.parse(allocator, body) catch |err| switch (err) {
        error.InputEmpty => {
            res.status = 400;
            try res.json(.{ .parseErrors = &.{"INPUT_EMPTY"} }, .{});
            return;
        },
        error.InputTooLarge => {
            res.status = 400;
            try res.json(.{ .parseErrors = &.{"INPUT_TOO_LARGE"} }, .{});
            return;
        },
    };

    try res.json(parsed_recipe, .{});
}
