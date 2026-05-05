const std = @import("std");

pub const ParseError = error{
    EmptyRequestLine,
    InvalidMethod,
    InvalidRequestLine,
    HeaderOverflow,
};

pub const MAX_HEADERS = 64;

pub const Request = struct {
    method: Method,
    uri: []const u8,
    version: []const u8,

    headers: []Header,

    // body: ?[]u8,

    // pub fn toString(self: Request) []u8 {
    //     todo
    // }
};

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Body = []u8;

pub const Method = enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    PATCH,

    pub fn parse(str: []const u8) !Method {
        return std.meta.stringToEnum(Method, str) orelse return ParseError.InvalidRequestLine;
    }
};

const BumpBuffer = struct {
    buf: []u8,
    used: usize,

    fn init(buf: []u8) BumpBuffer {
        return .{
            .buf = buf,
            .used = 0,
        };
    }

    fn dupe(self: *BumpBuffer, src: []const u8) ![]const u8 {
        if (src.len > self.buf.len - self.used) return error.ScratchOverflow;
        const dst = self.buf[self.used..][0..src.len];
        @memcpy(dst, src);
        self.used += src.len;
        return dst;
    }
};

pub fn readRequest(reader: *std.Io.Reader, h_buf: *[MAX_HEADERS]Header, s_buf: []u8) !Request {
    // for request line strings + header kv pairs
    var b_buf = BumpBuffer.init(s_buf);

    // parse req line
    const req_line = try nextLine(reader) orelse "";
    if (req_line.len == 0) return ParseError.EmptyRequestLine;

    var line_parts = std.mem.splitScalar(u8, req_line, ' ');
    const method = try Method.parse(line_parts.next() orelse "");
    const uri = try b_buf.dupe(line_parts.next() orelse return ParseError.InvalidRequestLine);
    const version = try b_buf.dupe(line_parts.next() orelse return ParseError.InvalidRequestLine);

    // parse headers
    var i: usize = 0;
    while (try nextLine(reader)) |line| : (i += 1) {
        if (i >= MAX_HEADERS) return ParseError.HeaderOverflow;
        var header_parts = std.mem.splitScalar(u8, line, ':');

        h_buf[i] = .{ .name = try b_buf.dupe(header_parts.first()), .value = try b_buf.dupe(std.mem.trim(u8, header_parts.rest(), &[_]u8{ ' ', '\t' })) };
    }

    // parse body
    // TODO

    return .{
        .method = method,
        .uri = uri,
        .version = version,
        .headers = h_buf[0..i],
    };
}

fn nextLine(reader: *std.Io.Reader) !?[]const u8 {
    const line = try reader.takeDelimiter('\n') orelse return null;
    const trimmed = std.mem.trimEnd(u8, line, &[_]u8{'\r'});
    return if (trimmed.len != 0) trimmed else null;
}
