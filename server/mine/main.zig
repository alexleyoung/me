const std = @import("std");

const ping = @import("pington");

fn index(srv: ping.Server, _: ping.Request, res: ping.Response) !void {
    const html = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), srv.io, "static/index.html", srv.alloc, .unlimited);

    try res.status(200);
    try res.setInt("Content-Length", html.len);
    try res.send(html);

    srv.alloc.free(html);
}

fn err(srv: ping.Server, _: ping.Request, res: ping.Response) !void {
    const html = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), srv.io, "static/err.html", srv.alloc, .unlimited);

    try res.status(404);
    try res.setInt("Content-Length", html.len);
    try res.send(html);

    srv.alloc.free(html);
}

pub fn main(init: std.process.Init) !void {
    var srv = try ping.Server.init(init.io, init.gpa);
    defer srv.deinit();

    try srv.get("/", index);
    try srv.get("", index);
    srv.notFoundHandler = err;

    const port: u16 = 7878;
    std.debug.print("Listening on port {d}\n", .{port});
    try srv.listen(init.io, port);
}
