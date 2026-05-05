const std = @import("std");
const Io = std.Io;

const server = @import("server");

// should this be its own module thinking emoji
const http = @import("http.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const srv = try server.Server.init(io, "127.0.0.1", 7878);
    var listener = try srv.listen();

    while (true) {
        const conn = try listener.accept(io);
        defer conn.close(io);

        var reader_buf: [1024]u8 = undefined;
        var reader = conn.reader(io, &reader_buf);

        var header_buf: [http.MAX_HEADERS]http.Header = undefined;
        var scratch_buf: [8192]u8 = undefined;
        const req = http.readRequest(&reader.interface, &header_buf, &scratch_buf) catch continue;

        std.debug.print("{s} {s} {s}\n{s}: {s}\n", .{ @tagName(req.method), req.uri, req.version, req.headers[0].name, req.headers[0].value });
    }
}
