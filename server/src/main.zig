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
        switch (req.method) {
            .GET => {
                var index = try std.Io.Dir.cwd().openFile(io, "index.html", .{});
                defer index.close(io);
                var html_reader_buf: [1024]u8 = undefined;
                var html_reader = index.reader(io, &html_reader_buf);

                var writer_buf: [8192]u8 = undefined;
                var writer = conn.writer(io, &writer_buf);
                try writer.interface.print("{s} 200 OK\r\nContent-Length: {d}\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n", .{
                    req.version.get(&reader_buf),
                    try index.length(io),
                });

                _ = try html_reader.interface.streamRemaining(&writer.interface);
                try writer.interface.flush();
            },
            else => {},
        }
    }
}
