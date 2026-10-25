const std = @import("std");
const builtin = @import("builtin");

pub const Cursor = @import("cursor.zig").Cursor;
pub const Style = @import("style.zig").Style;
pub const Platform = @import("platform.zig").Platform;
pub const Terminal = @import("terminal.zig").Terminal;

/// Terminal output file, On windows this is "CONOUT$", on unix systems this is "/dev/tty"
pub inline fn sysout(io: std.Io) !std.Io.File{
    return if(builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysout(io)
    else 
        @import("sys/unix.zig").sysout(io);
}

/// Manages terminal inits all terminal utlity structs  
pub const Tty = struct{
    outwriter: std.Io.File.Writer,
    platform: Platform,
    cursor: Cursor,
    style: Style,
    terminal: Terminal,

    pub fn init(self: *Tty, io: std.Io, file: std.Io.File, buffer: []u8) void{
        self.platform = .init(&file);
        self.outwriter = .init(file, io, buffer);
        self.cursor = .{
            .platform = &self.platform,
            .writer = &self.outwriter
        };

        self.style = .{
            .platform = &self.platform,
            .writer = &self.outwriter
        };
    
        self.terminal = .{
            .platform = &self.platform,
            .writer = &self.outwriter,
        };
    }    
    
    pub fn writer(self: *Tty) *std.Io.Writer{
        return &self.outwriter.interface;
    }
};
