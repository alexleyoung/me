const std = @import("std");

const http = @import("http.zig");

pub const Request = http.Request;
pub const Response = http.Response;

pub const Server = struct {
    // must be threadsafe
    io: std.Io,
    alloc: std.mem.Allocator,
    threads: std.Io.Threaded,

    listening: bool,

    _routes: RouteMap,
    _middleware: std.ArrayList(Handler),
    notFoundHandler: ?Handler,

    pub fn init(io: std.Io, alloc: std.mem.Allocator) !Server {
        return .{
            .io = io,
            .alloc = alloc,
            .threads = std.Io.Threaded.init(alloc, .{}),
            .listening = false,
            ._routes = RouteMap.init(alloc),
            ._middleware = try std.ArrayList(Handler).initCapacity(alloc, 4),
            .notFoundHandler = null,
        };
    }

    pub fn deinit(self: *Server) void {
        self._routes.deinit();
        self._middleware.deinit(self.alloc);
        self.threads.deinit();
    }

    /// Start the http server loop
    pub fn listen(self: *Server, port: u16) !void {
        const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", port);
        var listener = try addr.listen(self.io, .{ .mode = .stream, .protocol = .tcp });
        defer listener.deinit(self.io);

        var group: std.Io.Group = .init;
        defer group.await(self.threads.io()) catch {};

        self.listening = true;
        while (true) {
            const conn = try listener.accept(self.io);
            try group.concurrent(self.threads.io(), handleConn, .{ self, conn });
        }
    }

    pub const RouteMap = std.HashMap(Route, Handler, RouteContext, std.hash_map.default_max_load_percentage);

    pub const Route = struct {
        uri: []const u8,
        method: http.Method,
    };

    pub const Handler = *const fn (server: *Server, req: http.Request, res: http.Response) anyerror!void;

    pub const RouteContext = struct {
        pub fn hash(_: RouteContext, r: Route) u64 {
            // wyhash is default zig (and others) hash algorithm
            var h = std.hash.Wyhash.init(0);
            h.update(r.uri);
            h.update(std.mem.asBytes(&r.method));
            return h.final();
        }

        pub fn eql(_: RouteContext, a: Route, b: Route) bool {
            return a.method == b.method and std.mem.eql(u8, a.uri, b.uri);
        }
    };

    pub fn middleware(self: *Server, handler: Handler) !void {
        std.debug.assert(!self.listening);
        try self._middleware.append(self.alloc, handler);
    }

    pub fn get(self: *Server, uri: []const u8, handler: Handler) !void {
        std.debug.assert(!self.listening);
        try self._routes.put(.{ .uri = uri, .method = .GET }, handler);
    }
};

fn defaultNotFoundHandler(_: *Server, _: http.Request, res: http.Response) !void {
    try res.status(404);
    try res.setInt("Content-Length", 0);
    try res.send("");
}

fn handleConn(srv: *Server, conn: std.Io.net.Stream) std.Io.Cancelable!void {
    handleConnInner(srv, conn) catch |err| switch (err) {
        error.Canceled => return error.Canceled,
        else => std.log.err("conn handler: {s}", .{@errorName(err)}),
    };
}

fn handleConnInner(srv: *Server, conn: std.Io.net.Stream) !void {
    var r_buf: [8192]u8 = undefined;
    var reader = conn.reader(srv.io, &r_buf);
    const req = try http.readRequest(&reader.interface);

    var w_buf: [1024]u8 = undefined;
    var writer = conn.writer(srv.io, &w_buf);
    const res = http.Response{ .writer = &writer.interface };

    // TODO: middleware here

    if (srv._routes.get(.{ .uri = req.uri.get(&r_buf), .method = req.method })) |handler| {
        try handler(srv, req, res);
    } else {
        try (srv.notFoundHandler orelse defaultNotFoundHandler)(srv, req, res);
    }
    try writer.interface.flush();
}
