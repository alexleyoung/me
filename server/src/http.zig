const std = @import("std");

pub const ParseError = error{
    EmptyRequestLine,
    InvalidMethod,
    InvalidRequestLine,
    HeaderOverflow,
};

pub const Request = struct {
    method: Method,
    uri: Slice,
    version: Slice,
    headers: Headers,

    pub const Headers = struct {
        source: Slice,

        pub fn iterate(headers: Headers, buffer: []const u8) Iterator {
            return .{ .remaining = headers.source.get(buffer) };
        }

        pub const Iterator = struct {
            remaining: []const u8,

            pub fn next(iter: *Iterator) ?Header {
                const name, iter.remaining = std.mem.cutScalar(u8, iter.remaining, ':') orelse return null;
                const value, iter.remaining = std.mem.cut(u8, iter.remaining, "\r\n") orelse .{ iter.remaining, "" };
                return .{
                    .name = name,
                    .value = value,
                };
            }
        };
    };

    // body: ?[]u8,
};

/// Wrapper of a connection stream's writer.
/// MUST call status, set, and send in that order, as
/// these helpers append to the stream.
pub const Response = struct {
    writer: *std.Io.Writer,

    /// Write the status line of the response
    pub fn status(self: Response, code: u16) !void {
        try self.writer.print("HTTP/1.1 {d} {s}\r\n", .{ code, statusMessage(code) });
    }

    /// Set header [k] with value [v]
    pub fn set(self: Response, key: []const u8, val: []const u8) !void {
        try self.writer.print("{s}: {s}\r\n", .{ key, val });
    }

    /// Write the body of the response with [data]
    pub fn send(self: Response, data: []const u8) !void {
        try self.writer.writeAll("\r\n");
        try self.writer.writeAll(data);
    }
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

pub fn readRequest(reader: *std.Io.Reader) !Request {
    // parse req line
    const method_slice, const uri, const version = try readLineSplitScalar(reader, 3, ' ') orelse return error.InvalidRequestLine;
    const method = try Method.parse(method_slice.get(reader.buffer));

    // parse general headers
    const headers_start = reader.seek;
    while (try readLineSplitScalar(reader, 2, ':')) |header| {
        const key, const value = header;
        _ = key;
        _ = value;
    }
    const headers_end = reader.seek;

    // parse body
    // TODO

    return .{
        .method = method,
        .uri = uri,
        .version = version,
        .headers = .{
            .source = .{
                .start = headers_start,
                .len = headers_end - headers_start,
            },
        },
    };
}

/// Absolute indexes into reader.buffer.
/// We use indexes instead of pointers because some readers may reallocate the
/// buffer (e.g., std.Io.Reader.Allocating).
const Slice = struct {
    start: usize,
    len: usize,

    pub fn get(slice: Slice, buffer: []const u8) []const u8 {
        return buffer[slice.start..][0..slice.len];
    }
};

fn readLine(reader: *std.Io.Reader) !?Slice {
    const start = reader.seek;
    const line = try reader.takeDelimiter('\n') orelse return null;
    const trimmed = std.mem.trimEnd(u8, line, "\r");
    return if (trimmed.len != 0) .{
        .start = start,
        .len = trimmed.len,
    } else null;
}

fn readLineSplitScalar(reader: *std.Io.Reader, comptime n: usize, delimiter: u8) !?[n]Slice {
    std.debug.assert(n > 0);
    const line = try readLine(reader) orelse return null;
    var slices: [n]Slice = undefined;
    var index = line.start;
    for (&slices, 0..) |*slice, i| {
        if (i == n - 1) {
            slice.* = .{
                .start = index,
                .len = (line.start + line.len) - index,
            };
        } else {
            const delimiter_index = std.mem.findScalarPos(u8, reader.buffer, index, delimiter) orelse return null;
            slice.* = .{
                .start = index,
                .len = delimiter_index - index,
            };
            index = delimiter_index + 1;
        }
    }
    return slices;
}

fn statusMessage(code: u16) []const u8 {
    return switch (code) {
        404 => "Not found",
        else => "Unknown error",
    };
}
