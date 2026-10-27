const std = @import("std");
const builtin = @import("builtin");
const OutputState = @import("state.zig").OutputState; 
const options = @import("options");

/// This structure contains functions, which can be used to manipulate the cursor
pub const Cursor = struct{
    outputstate: *OutputState,
    writer: *std.Io.File.Writer,
    
    /// This enum contains options to change the shape of the cursor, and the blinking of the cursor
    pub const CursorStyle = enum{
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

    /// Moves the cursor n cells down 
    pub fn moveDown(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(info.dwCursorPosition.X),
                    .Y = @intCast(info.dwCursorPosition.Y+@as(i16, @intCast(n)))
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if(n != 0)
            self.writer.interface.print("\x1b[{}B", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells up 
    pub fn moveUp(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(info.dwCursorPosition.X),
                    .Y = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.Y))-|n)))
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if(n != 0)
            self.writer.interface.print("\x1b[{}A", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells to the left
    pub fn moveLeft(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.X))-|n))),
                    .Y = @intCast(info.dwCursorPosition.Y) 
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }

        if(n != 0)
            self.writer.interface.print("\x1b[{}D", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor n cells to the right 
    pub fn moveRight(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(info.dwCursorPosition.X+@as(i16, @intCast(n))),
                    .Y = @intCast(info.dwCursorPosition.Y) 
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        if(n != 0)
            self.writer.interface.print("\x1b[{}C", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to column n
    pub fn moveToColumn(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(n-|1),
                    .Y = @intCast(info.dwCursorPosition.Y) 
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.writer.interface.print("\x1b[{}G", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to row n
    pub fn moveToRow(self: *Cursor, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
                
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(info.dwCursorPosition.X),
                    .Y = @intCast(n-|1) 
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.writer.interface.print("\x1b[{}d", .{n}) catch return error.FailedToMoveCursor;
    }

    /// Moves the cursor to the speficied positon(x, y)
    pub fn moveTo(self: *Cursor, x: u16, y: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToMoveCursor;
                if(win.winapi.SetConsoleCursorPosition(self.writer.file.handle, .{
                    .X = @intCast(x-|1),
                    .Y = @intCast(y-|1) 
                }) == .FALSE) return error.FailedToMoveCursor;
                return;
            }
        }
        self.writer.interface.print("\x1b[{};{}H", .{x, y}) catch return error.FailedToMoveCursor;
    }

    /// Hides the cursor 
    pub fn hide(self: *Cursor) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToHideCursor;
                var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                if(win.winapi.GetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;
                
                cinfo.bVisible = .FALSE;
                if(win.winapi.SetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?25l") catch return error.FailedToHideCursor;
    }

    /// Shows the cursor 
    pub fn show(self: *Cursor) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToShowCursor;
                var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                if(win.winapi.GetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;
                
                cinfo.bVisible = .TRUE;
                if(win.winapi.SetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?25h") catch return error.FailedToShowCursor;
    }

    /// Saves the cursor positon
    pub fn savePosition(self: *Cursor) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const sys = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToSavePostion;
                var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(sys.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == sys.windows.BOOL.FALSE) return error.FailedToSavePostion;
               
                self.outputstate.saved_cursor_postion = info.dwCursorPosition;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[s") catch return error.FailedToSavePostion;
    }

    /// Restores the cursor positon
    pub fn restorePosition(self: *Cursor) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const sys = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToRestorePostion;
                if(sys.winapi.SetConsoleCursorPosition(self.writer.file.handle, self.outputstate.saved_cursor_postion) == sys.windows.BOOL.FALSE) return error.FailedToRestorePostion;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[s") catch return error.FailedToRestorePostion;
    }

    /// Sets the cursor style.
    /// On Windows, when VT output is unavailable, the following styles may
    /// be supported on some terminals, but support is not guaranteed:
    /// - `SteadyUnderScore`
    /// - `SteadyBlock`
    /// - `BlinkingUnderScore`
    /// - `BlinkingBlock`
    ///
    /// Whether the cursor blinks is terminal dependent
    pub fn setCursorStyle(self: *Cursor, style: CursorStyle) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                switch (style) {
                    .DefaultUserShape => {
                        self.writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if(win.winapi.GetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if(self.outputstate.default_size != 0)
                            cinfo.dwSize = self.outputstate.default_size;
                        if(win.winapi.SetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    .SteadyUnderScore, .BlinkingUnderScore => {
                        self.writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if(win.winapi.GetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if(self.outputstate.default_size == 0)
                            self.outputstate.default_size = cinfo.dwSize;
                        
                        cinfo.dwSize = 20;
                        if(win.winapi.SetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    .SteadyBlock, .BlinkingBlock => {
                        self.writer.flush() catch return error.FailedToSetCursorStyle;
                        var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                        if(win.winapi.GetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                        if(self.outputstate.default_size == 0)
                            self.outputstate.default_size = cinfo.dwSize;
                        
                        cinfo.dwSize = 100;
                        if(win.winapi.SetConsoleCursorInfo(self.writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    },
                    else => {return;}
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
        // Check if this its better to format, or match and use .writeAll 
        self.writer.interface.print("\x1b[{}\x20q", .{value}) catch return error.FailedToSetCursorStyle;
    }
};
