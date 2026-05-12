const std = @import("std");

const main = @import("main.zig");
const http = @import("http.zig");

pub fn handle(ctx: main.Context, conn: std.Io.net.Stream, req: http.Request) !void {
    switch (req.method) {
        .GET => {
            var writer_buf: [8192]u8 = undefined;
            var writer = conn.writer(ctx.io, &writer_buf);
            try writer.interface.print("{s} 200 OK\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
                "HTTP/1.1",
                ctx.pages.index.len,
            });
            try writer.interface.writeAll(ctx.pages.index);
            try writer.interface.flush();
        },
        else => {},
    }
}
