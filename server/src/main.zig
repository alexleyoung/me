const std = @import("std");
const Io = std.Io;

const server = @import("server");

// should this be its own module thinking emoji
const http = @import("http.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const srv = try server.Server.init(io, "127.0.0.1", 7878);
    var listener = try srv.listen();
    defer listener.deinit(io);

    while (true) {
        const conn = try listener.accept(io);
        defer conn.close(io);

        var reader_buf: [8192]u8 = undefined;
        var reader = conn.reader(io, &reader_buf);
        defer reader.interface.tossBuffered();

        const req = http.readRequest(&reader.interface) catch continue;

        std.log.debug("{t} {s} {s}", .{ req.method, req.uri.get(&reader_buf), req.version.get(&reader_buf) });
        var headers_iter = req.headers.iterate(&reader_buf);
        while (headers_iter.next()) |h| {
            std.log.debug("  {s}:{s}", .{ h.name, h.value });
        }
    }
}
