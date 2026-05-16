const std = @import("std");

const http = @import("http.zig");

pub const Request = http.Request;
pub const Response = http.Response;

/// My custom http server struct. Express-like API which lets you declare
/// routes and pass callbacks to be run on that route.
pub const Server = struct {
    io: std.Io,
    alloc: std.mem.Allocator,

    routes: RouteMap,
    middleware: std.ArrayList(Handler),
    notFoundHandler: ?Handler,

    pub fn init(io: std.Io, alloc: std.mem.Allocator) !Server {
        return .{
            .io = io,
            .alloc = alloc,
            .routes = RouteMap.init(alloc),
            .middleware = try std.ArrayList(Handler).initCapacity(alloc, 4),
            .notFoundHandler = null,
        };
    }

    pub fn deinit(self: *Server) void {
        self.routes.deinit();
        self.middleware.deinit(self.alloc);
    }

    /// Start the http server loop
    pub fn listen(self: Server, io: std.Io, port: u16) !void {
        const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", port);
        var listener = try addr.listen(io, .{ .mode = .stream, .protocol = .tcp });
        defer listener.deinit(io);

        while (true) {
            const conn = try listener.accept(io);
            try handleConn(self, conn);
        }
    }

    pub const RouteMap = std.HashMap(Route, Handler, RouteContext, std.hash_map.default_max_load_percentage);

    pub const Route = struct {
        uri: []const u8,
        method: http.Method,
    };

    pub const Handler = *const fn (server: Server, req: http.Request, res: http.Response) anyerror!void;

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

    pub fn get(self: *Server, uri: []const u8, handler: Handler) !void {
        try self.routes.put(.{ .uri = uri, .method = .GET }, handler);
    }
};

fn defaultNotFoundHandler(_: Server, _: http.Request, res: http.Response) !void {
    try res.status(404);
    try res.send("");
}

fn handleConn(srv: Server, conn: std.Io.net.Stream) !void {
    var r_buf: [8192]u8 = undefined;
    var reader = conn.reader(srv.io, &r_buf);
    const req = try http.readRequest(&reader.interface);

    var w_buf: [1024]u8 = undefined;
    var writer = conn.writer(srv.io, &w_buf);
    const res = http.Response{ .writer = &writer.interface };

    if (srv.routes.get(.{ .uri = req.uri.get(&r_buf), .method = req.method })) |handler| {
        try handler(srv, req, res);
    } else {
        try (srv.notFoundHandler orelse defaultNotFoundHandler)(srv, req, res);
    }
    try writer.interface.flush();
}
