const std = @import("std");

pub inline fn sysOut(io: std.Io) !std.Io.File{
    return std.Io.Dir.cwd().openFile(io, "/dev/tty", .{
        .mode = .read_write,
    }) catch return error.FailedToOpenTty;
}
