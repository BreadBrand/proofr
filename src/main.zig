const std = @import("std");
const httpz = @import("httpz");
const handler = @import("./handler.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var server = try httpz.Server(void).init(init.io, allocator, .{
        .address = .localhost(4242),
    }, {});
    defer {
        server.stop();
        server.deinit();
    }

    const cors = try server.middleware(httpz.middleware.Cors, .{
        .origin = "https://bread-machine.dev",
        .methods = "POST, OPTIONS",
        .headers = "Content-Type",
    });

    var router = try server.router(.{.middlewares = &.{cors}});
    router.options("/parse", options, .{});
    router.post("/parse", handler.parse, .{});

    std.debug.print("listening on http://localhost:4242\n", .{});
    try server.listen();
}

fn options(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
}
