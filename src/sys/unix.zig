const std = @import("std");

pub fn sysout(io: std.Io) !std.Io.File{
    return std.Io.Dir.cwd().openFile(io, "/dev/tty", .{
        .mode = .read_write,
    }) catch return error.FailedToOpenTty;
}

pub inline fn enableOutVT(_: std.Io.File) void{}
