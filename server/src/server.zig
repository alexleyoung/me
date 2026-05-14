const std = @import("std");

const http = @import("http.zig");
const handlers = @import("handlers.zig");

/// My custom http server struct. Express-like API which lets you declare
/// routes and pass callbacks to be run on that route.
pub const Server = struct {
    alloc: std.mem.Allocator,
    routes: RouteMap,

    pub const RouteMap = std.HashMap(Route, Handler, RouteContext, std.hash_map.default_max_load_percentage);

    pub const Route = struct {
        uri: []const u8,
        method: http.Method,
    };

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

    pub const Handler = *const fn (conn: std.Io.net.Stream) anyerror!void;

    pub fn init(alloc: std.mem.Allocator) !Server {
        return .{ .routes = RouteMap.init(alloc) };
    }

    pub fn deinit(self: Server) void {
        self.routes.deinit();
    }

    pub fn get(self: *Server, uri: []u8, handler: Handler) !void {
        try self.routes.put(.{ .uri = uri, .method = .GET }, handler);
    }
};
