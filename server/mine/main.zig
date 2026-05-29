const std = @import("std");

const ping = @import("pington");
const pages = @import("pages.zig");

pub fn main(init: std.process.Init) !void {
    var srv = try ping.Server.init(init.io, init.gpa);
    defer srv.deinit();

    // pages
    try srv.get("/", pages.index);
    try srv.get("/about", pages.about);
    srv.notFoundHandler = pages.err;

    const port: u16 = 7878;
    std.debug.print("Listening on port {d}\n", .{port});
    try srv.listen(init.io, port);
}
