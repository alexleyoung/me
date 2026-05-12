const std = @import("std");

const http = @import("http.zig");
const server = @import("server.zig");

pub fn handle(ctx: *const server.Context, conn: std.Io.net.Stream, req: http.Request) !void {
    switch (req.method) {
        .GET => try handleGet(ctx, conn),
        else => {},
    }
}

fn handleGet(ctx: *const server.Context, conn: std.Io.net.Stream) !void {
    var writer_buf: [8192]u8 = undefined;
    var writer = conn.writer(ctx.io, &writer_buf);
    try writer.interface.print("{s} 200 OK\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
        "HTTP/1.1",
        ctx.pages.index.len,
    });
    try writer.interface.writeAll(ctx.pages.index);
    try writer.interface.flush();
}
