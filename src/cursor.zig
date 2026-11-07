const std = @import("std");
const builtin = @import("builtin");
const event = @import("event.zig");
const options = @import("options");

const OutputState = @import("state.zig").OutputState;
const Tty = @import("root.zig").Tty;
const Input = @import("input.zig").Input;

/// This structure contains functions, which can be used to manipulate the cursor
pub const Cursor = struct {
    tty: *Tty,

    /// This enum contains options to change the shape of the cursor, and the blinking of the cursor
    pub const CursorStyle = enum {
        /// The default cursor shape used in the terminal
        DefaultUserShape,

        /// A block cursor shape `■`
        SteadyBlock,

        /// A blinking version of `SteadyBlock`
        BlinkingBlock,

        /// An underscore cursor shape `_`
        SteadyUnderScore,

        /// A blinking version of `SteadyUnderScore`
        BlinkingUnderScore,

        /// A bar cursor shape `|`
        SteadyBar,
        
        /// A blinking version of `SteadyBar`
        BlinkingBar,
    };

    /// Creates a `Cursor` structure
    pub inline fn init(tty: *Tty) Cursor {
        return .{ .tty = tty };
    }

    /// Moves the cursor n cells down
    pub fn moveDown(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(info.dwCursorPosition.X), .Y = @intCast(info.dwCursorPosition.Y + @as(i16, @intCast(n))) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if (n != 0)
            self.tty.out_writer.interface.print("\x1b[{}B", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells up
    pub fn moveUp(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(info.dwCursorPosition.X), .Y = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.Y)) -| n))) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if (n != 0)
            self.tty.out_writer.interface.print("\x1b[{}A", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells to the left
    pub fn moveLeft(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.X)) -| n))), .Y = @intCast(info.dwCursorPosition.Y) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }

        if (n != 0)
            self.tty.out_writer.interface.print("\x1b[{}D", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells to the right
    pub fn moveRight(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(info.dwCursorPosition.X + @as(i16, @intCast(n))), .Y = @intCast(info.dwCursorPosition.Y) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if (n != 0)
            self.tty.out_writer.interface.print("\x1b[{}C", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to column n
    pub fn moveToColumn(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(n -| 1), .Y = @intCast(info.dwCursorPosition.Y) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.tty.out_writer.interface.print("\x1b[{}G", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to row n
    pub fn moveToRow(self: *Cursor, n: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;

                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(info.dwCursorPosition.X), .Y = @intCast(n -| 1) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.tty.out_writer.interface.print("\x1b[{}d", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to the specified positon(x, y)
    pub fn moveTo(self: *Cursor, x: u16, y: u16) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToMoveCursor;
                if (win.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, .{ .X = @intCast(x -| 1), .Y = @intCast(y -| 1) }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.tty.out_writer.interface.print("\x1b[{};{}H", .{ x, y }) catch return error.FailedToMoveCursor;
    }

    /// Hides the cursor
    pub fn hide(self: *Cursor) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToHideCursor;
                var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                if (win.winapi.GetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;

                cinfo.bVisible = .FALSE;
                if (win.winapi.SetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;
                return;
            }
        }
        self.tty.out_writer.interface.writeAll("\x1b[?25l") catch return error.FailedToHideCursor;
    }

    /// Shows the cursor
    pub fn show(self: *Cursor) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToShowCursor;
                var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                if (win.winapi.GetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;

                cinfo.bVisible = .TRUE;
                if (win.winapi.SetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;
                return;
            }
        }
        self.tty.out_writer.interface.writeAll("\x1b[?25h") catch return error.FailedToShowCursor;
    }

    /// Saves the cursor positon
    pub fn savePosition(self: *Cursor) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const sys = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToSavePostion;
                var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if (sys.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == sys.windows.BOOL.FALSE) return error.FailedToSavePostion;

                self.tty.output_state.saved_cursor_postion = info.dwCursorPosition;
                return;
            }
        }
        self.tty.out_writer.interface.writeAll("\x1b[s") catch return error.FailedToSavePostion;
    }

    /// Restores the cursor positon
    pub fn restorePosition(self: *Cursor) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const sys = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                self.tty.out_writer.flush() catch return error.FailedToRestorePostion;
                if (sys.winapi.SetConsoleCursorPosition(self.tty.out_writer.file.handle, self.tty.output_state.saved_cursor_postion) == sys.windows.BOOL.FALSE) return error.FailedToRestorePostion;
                return;
            }
        }
        self.tty.out_writer.interface.writeAll("\x1b[s") catch return error.FailedToRestorePostion;
    }

    /// Sets the cursor style.
    /// On Windows, when VT output is unavailable, the following styles may
    /// be supported on some terminals, but support is not guaranteed:
    /// - `SteadyUnderScore`
    /// - `SteadyBlock`
    /// - `BlinkingUnderScore`
    /// - `BlinkingBlock`
    ///
    /// In this case 'Blinking' and 'Steady' will have the same effect
    pub fn setCursorStyle(self: *Cursor, style: CursorStyle) !void {
        if (builtin.os.tag == .windows and options.out != .vt) {
            const win = @import("sys/windows/root.zig");
            if (options.out == .native or !self.tty.output_state.supported.VtOut) {
                switch (style) {
                    .DefaultUserShape => {
                        self.tty.out_writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if (win.winapi.GetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if (self.tty.output_state.default_size != 0)
                            cinfo.dwSize = self.tty.output_state.default_size;
                        if (win.winapi.SetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    .SteadyUnderScore, .BlinkingUnderScore => {
                        self.tty.out_writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if (win.winapi.GetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if (self.tty.output_state.default_size == 0)
                            self.tty.output_state.default_size = cinfo.dwSize;

                        cinfo.dwSize = 20;
                        if (win.winapi.SetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    .SteadyBlock, .BlinkingBlock => {
                        self.tty.out_writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if (win.winapi.GetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if (self.tty.output_state.default_size == 0)
                            self.tty.output_state.default_size = cinfo.dwSize;

                        cinfo.dwSize = 100;
                        if (win.winapi.SetConsoleCursorInfo(self.tty.out_writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    else => {
                        return;
                    },
                }
                return;
            }
        }
        const value: u8 = switch (style) {
            .DefaultUserShape => 0,

            .BlinkingBlock => 1,
            .SteadyBlock => 2,

            .BlinkingUnderScore => 3,
            .SteadyUnderScore => 4,

            .BlinkingBar => 5,
            .SteadyBar => 6,
        };
        self.tty.out_writer.interface.print("\x1b[{}\x20q", .{value}) catch return error.FailedToSetCursorStyle;
    }
};
