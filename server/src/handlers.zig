const std = @import("std");

const http = @import("http.zig");
const server = @import("server.zig");

pub fn handle(ctx: *const server.Context, conn: std.Io.net.Stream, req: http.Request, req_buf: []const u8) !void {
    switch (req.method) {
        .GET => try handleGet(ctx, conn, req, req_buf),
        else => {},
    }
}

fn handleGet(ctx: *const server.Context, conn: std.Io.net.Stream, req: http.Request, req_buf: []const u8) !void {
    const uri = req.uri.get(req_buf);

    var writer_buf: [8192]u8 = undefined;
    var writer = conn.writer(ctx.io, &writer_buf);

    // TODO: think about how to do routing better
    if (uri.len == 0 or std.mem.eql(u8, uri, "/")) {
        try writer.interface.print("{s} 200 OK\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
            "HTTP/1.1",
            ctx.pages.index.len,
        });
        try writer.interface.writeAll(ctx.pages.index);
        try writer.interface.flush();
    } else {
        try writer.interface.print("{s} 404 ERROR\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
            "HTTP/1.1",
            ctx.pages.err.len,
        });
        try writer.interface.writeAll(ctx.pages.err);
        try writer.interface.flush();
    }
}
