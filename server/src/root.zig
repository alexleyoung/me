const std = @import("std");

const http = @import("http.zig");

/// My custom http server struct. Express-like API which lets you declare
/// routes and pass callbacks to be run on that route.
pub const Server = struct {
    alloc: std.mem.Allocator,
    routes: RouteMap,

    pub fn init(alloc: std.mem.Allocator) !Server {
        return .{ .alloc = alloc, .routes = RouteMap.init(alloc) };
    }

    pub fn deinit(self: *Server) void {
        self.routes.deinit();
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

    pub const Handler = *const fn (conn: std.Io.net.Stream) anyerror!void;

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

    pub fn get(self: *Server, uri: []u8, handler: Handler) !void {
        try self.routes.put(.{ .uri = uri, .method = .GET }, handler);
    }
};

fn handleConn(server: Server, conn: std.Io.net.Stream) !void {
    // TODO
    _ = server;
    _ = conn;
}
