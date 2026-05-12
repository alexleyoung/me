const std = @import("std");
const Io = std.Io;

const server = @import("server");

// should this be its own module thinking emoji
const http = @import("http.zig");
const handlers = @import("handlers.zig");

pub const Context = struct {
    io: std.Io,
    pages: Pages,

    pub const Pages = struct {
        index: []const u8,
        err: []const u8,
    };

    pub fn init(io: std.Io, alloc: std.mem.Allocator) !Context {
        const index = try std.Io.Dir.cwd().readFileAlloc(io, "static/index.html", alloc, .unlimited);
        const err = try std.Io.Dir.cwd().readFileAlloc(io, "static/err.html", alloc, .unlimited);

        const pages = Pages{ .index = index, .err = err };

        return Context{ .io = io, .pages = pages };
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    const ctx = try Context.init(io, gpa);

    const srv = try server.Server.init(io, "127.0.0.1", 7878);
    var listener = try srv.listen();
    defer listener.deinit(io);

    while (true) {
        const conn = try listener.accept(io);
        try handleConn(ctx, conn);
    }
}

fn handleConn(ctx: Context, conn: std.Io.net.Stream) !void {
    defer conn.close(ctx.io);

    var reader_buf: [8192]u8 = undefined;
    var reader = conn.reader(ctx.io, &reader_buf);
    defer reader.interface.tossBuffered();

    // TODO: actually handle this error(s)
    const req = try http.readRequest(&reader.interface);
    std.debug.print("handling {} request\n", .{req.method});
    try handlers.handle(ctx, conn, req);
}
