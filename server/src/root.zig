const std = @import("std");

/// A simple HTTP Server
pub const Server = struct {
    host: []const u8,
    port: u16,
    addr: std.Io.net.IpAddress,
    io: std.Io,

    pub fn init(io: std.Io, host: []const u8, port: u16) !Server {
        const addr = try std.Io.net.IpAddress.parseIp4(host, port);
        return .{
            .host = host,
            .port = port,
            .addr = addr,
            .io = io,
        };
    }

    /// Return TCP stream listener on [self.addr]
    pub fn listen(self: Server) !std.Io.net.Server {
        std.debug.print("Starting server on {s}:{d}", .{ self.host, self.port });
        return self.addr.listen(self.io, .{ .mode = .stream, .protocol = .tcp });
    }
};
