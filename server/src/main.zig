const std = @import("std");
const Io = std.Io;

const server = @import("server");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const srv = try server.Server.init(io, "127.0.0.1", 7878);
    var listener = try srv.listen();

    while (true) {
        const connection = try listener.accept(io);

        defer connection.close(io);
    }
}
