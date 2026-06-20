const std = @import("std");
const httpz = @import("httpz");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    var server = try httpz.Server(void).init(init.io, allocator, .{
        .address = .localhost(4242),
    }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.post("/parse", parse, .{});

    std.debug.print("listening on http://localhost:4242\n", .{});
    try server.listen();
}

fn parse(req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    res.status = 200;
    res.body = "{\"status\":\"ok\"}";
}
