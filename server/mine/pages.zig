const std = @import("std");

const ping = @import("pington");

pub fn index(srv: ping.Server, _: ping.Request, res: ping.Response) !void {
    const html = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), srv.io, "static/index.html", srv.alloc, .unlimited);

    try res.status(200);
    try res.setInt("Content-Length", html.len);
    try res.send(html);

    srv.alloc.free(html);
}

pub fn about(srv: ping.Server, _: ping.Request, res: ping.Response) !void {
    const html = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), srv.io, "static/about.html", srv.alloc, .unlimited);

    try res.status(200);
    try res.setInt("Content-Length", html.len);
    try res.send(html);

    srv.alloc.free(html);
}

pub fn err(srv: ping.Server, _: ping.Request, res: ping.Response) !void {
    const html = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), srv.io, "static/err.html", srv.alloc, .unlimited);

    try res.status(404);
    try res.setInt("Content-Length", html.len);
    try res.send(html);

    srv.alloc.free(html);
}
