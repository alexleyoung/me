const std = @import("std");

const server = @import("server.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var ctx = try server.Context.init(io, gpa);
    defer ctx.deinit(gpa);

    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 7878);
    var listener = try addr.listen(io, .{ .mode = .stream, .protocol = .tcp });
    defer listener.deinit(io);

    std.debug.print("Starting server on 127.0.0.1:7878\n", .{});

    while (true) {
        const conn = try listener.accept(io);
        try server.handleConn(&ctx, conn);
    }
}
