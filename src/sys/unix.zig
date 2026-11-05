const std = @import("std");
const Lazy = @import("../utils.zig").Lazy;

var tty_val: Lazy(anyerror!std.Io.File, struct{
    pub fn init(io: std.Io) !std.Io.File{
        return std.Io.Dir.cwd().openFile(io, "/dev/tty", .{
            .mode = .read_write,
        }) catch return error.FailedToOpenTty;
    }
}.init) = .{};

pub inline fn tty(io: std.Io) !std.Io.File{
    return tty_val.get(.{io});
}
