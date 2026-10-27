const std = @import("std");
const builtin = @import("builtin");

pub const Cursor = @import("cursor.zig").Cursor;
pub const Style = @import("style.zig").Style;
pub const OutputState = @import("state.zig").OutputState;
pub const Terminal = @import("terminal.zig").Terminal;

/// Returns the terminal output file, On windows this is "CONOUT$", on unix systems this is "/dev/tty"
///
/// For TUI applications, prefer this function over standard output.
/// This is especially important on older Windows consoles or when using
/// the WinAPI fallback, where using standard output for alternatescreen
/// operations may cause the original screen contents to be lost.
pub inline fn sysout(io: std.Io) !std.Io.File{
    return if(builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysout(io)
    else 
        @import("sys/unix.zig").sysout(io);
}

/// Manages terminal inits all terminal utlity structs  
pub const Tty = struct{
    outwriter: std.Io.File.Writer,
    outputstate: OutputState,
    cursor: Cursor,
    style: Style,
    terminal: Terminal,

    pub fn init(self: *Tty, io: std.Io, file: std.Io.File, buffer: []u8) void{
        self.outputstate = .init(&file);
        self.outwriter = .init(file, io, buffer);
        self.cursor = .{
            .outputstate = &self.outputstate,
            .writer = &self.outwriter
        };

        self.style = .{
            .outputstate = &self.outputstate,
            .writer = &self.outwriter
        };
    
        self.terminal = .{
            .outputstate = &self.outputstate,
            .writer = &self.outwriter,
        };
    }    
    
    pub fn writer(self: *Tty) *std.Io.Writer{
        return &self.outwriter.interface;
    }
};
