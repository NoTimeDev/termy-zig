const std = @import("std");
const builtin = @import("builtin");

pub const Cursor = @import("cursor.zig").Cursor;
pub const Style = @import("style.zig").Style;
pub const Terminal = @import("terminal.zig").Terminal;
pub const Input = @import("input.zig").Input;
pub const event = @import("event.zig");

pub const OutputState = @import("state.zig").OutputState;
pub const InputState = @import("state.zig").InputState;

/// Returns the terminal output file, On windows this is "CONOUT$", on unix systems this is "/dev/tty".
///
/// For TUI applications, prefer this function over standard output.
/// This is especially important on older Windows consoles or when using
/// the WinAPI fallback, where using standard output for alternatescreen
/// operations may cause the original screen contents to be lost.
pub inline fn sysOut() !std.Io.File {
    return if (builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysOut()
    else
        @import("sys/unix.zig").tty();
}

/// Returns the terminal input file, On windows this is "CONIN$", on unix systems this is "/dev/tty".
pub inline fn sysIn() !std.Io.File {
    return if (builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysIn()
    else
        @import("sys/unix.zig").tty();
}

pub const Tty = struct {
    io: std.Io,
    output_state: OutputState,
    input_state: InputState,

    out_writer: std.Io.File.Writer,
    in_file: std.Io.File,

    /// Creates a new Tty.
    ///
    /// Input is optional, but Output is required for all operations.
    /// If `in` is null, attempting to use `Input` will cause undefined behaviour.
    pub fn init(io: std.Io, out: std.Io.File, buffer: []u8, in: ?std.Io.File) Tty {
        return .{ .io = io, .output_state = .init(out), .input_state = if (in) |n| .init(n) else undefined, .out_writer = .init(out, io, buffer), .in_file = if (in) |n| n else undefined };
    }

    /// Returns a pointer to the output file's `std.Io.Writer` interface.
    pub fn writer(self: *Tty) *std.Io.Writer {
        return &self.out_writer.interface;
    }
};
