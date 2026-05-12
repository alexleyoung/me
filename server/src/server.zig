const std = @import("std");

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

        return .{
            .io = io,
            .pages = .{ .index = index, .err = err },
        };
    }

    pub fn deinit(self: *Context, alloc: std.mem.Allocator) void {
        alloc.free(self.pages.index);
        alloc.free(self.pages.err);
    }
};

pub fn handleConn(ctx: *const Context, conn: std.Io.net.Stream) !void {
    defer conn.close(ctx.io);

    var reader_buf: [8192]u8 = undefined;
    var reader = conn.reader(ctx.io, &reader_buf);
    defer reader.interface.tossBuffered();

    // TODO: actually handle this error(s)
    const req = try http.readRequest(&reader.interface);
    std.debug.print("handling {} request\n", .{req.method});
    try handlers.handle(ctx, conn, req);
}
