const std = @import("std");

const server = @import("pington");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var app = try server.Server.init(gpa);
    defer app.deinit();

    const port: u16 = 7878;
    std.debug.print("Listening on port {d}\n", .{port});
    try app.listen(io, port);
}
