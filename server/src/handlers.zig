const std = @import("std");

const http = @import("http.zig");

pub fn handle_req(req: http.Request) !void {
    switch (req.method) {
        .GET => {
            var writer_buf: [8192]u8 = undefined;
            var writer = conn.writer(io, &writer_buf);
            try writer.interface.print("{s} 200 OK\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
                req.version.get(&reader_buf),
                index.len,
            });
            try writer.interface.writeAll(index);
            try writer.interface.flush();
        },
        else => {},
    }
}
