const std = @import("std");

const server = @import("pington");

pub fn main(init: std.process.Init) !void {
    var app = try server.Server.init(init.io, init.gpa);
    defer app.deinit();

    const port: u16 = 7878;
    std.debug.print("Listening on port {d}\n", .{port});
    try app.listen(init.io, port);
}

// fn index(conn: std.Io.net.Stream) !void {}
