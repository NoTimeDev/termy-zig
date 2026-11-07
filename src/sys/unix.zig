const std = @import("std");
const builtin = @import("builtin");
const Lazy = @import("../utils.zig").Lazy;
const Ring = @import("../utils.zig").Ring;

var tty_val: Lazy(anyerror!std.Io.File, struct{
    pub fn init() !std.Io.File{
        const fd = std.posix.openat(std.posix.AT.FDCWD, "/dev/tty", .{ .ACCMODE =  .RDWR}, 0) catch return error.FailedToOpenTty;

        return .{
            .handle = fd,
            .flags = .{ .nonblocking = false}
        };
    }
}.init) = .{};


// Lossy on perpouse
pub var resizes: if(builtin.os.tag == .windows) struct {} else Ring(struct{rows: u16, columns: u16}, 128) = .{};
pub var inited: bool = false;

pub fn handleWinch(_: std.posix.SIG) callconv(.c) void{
    var ws: std.posix.winsize = undefined;
    if(std.posix.errno(std.posix.system.ioctl( (tty_val.get(.{}) catch return).handle, std.posix.T.IOCGWINSZ, @intFromPtr(&ws))) == .SUCCESS){
        resizes.push(.{
            .rows = ws.row,
            .columns = ws.col
        });
    }
}

pub fn init_resizecatch() void{    
    const action: std.posix.Sigaction = .{
        .handler = .{ .handler = handleWinch },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };

    std.posix.sigaction(.WINCH, &action, null);
    inited = true;
}

pub inline fn tty() !std.Io.File{
    return tty_val.get(.{});
}

