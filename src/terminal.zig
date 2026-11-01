const OutputState = @import("state.zig").OutputState;
const InputState = @import("state.zig").InputState;
const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");

/// Provides functions to change how the terminal behaves
pub const Terminal = struct {
    outputstate: *OutputState,
    inputstate: *InputState,
    inhandle: std.Io.File.Handle,
    writer: *std.Io.File.Writer,
    /// A enum containing the types of clearing operations
    pub const ClearType = enum {
        /// All cells 
        All,
        /// All cells including history
        Purge,
        /// All cells from the cursor position downwords
        FromCursorDown,
        /// All cells from the cursor position upwards
        FromCursorUp,
        /// All cells at the current cursor row 
        CurrentRow,
        /// All cells from the cursor position until the end of the row 
        UntilRowEnd,
    };

    /// Inits a `Terminal` structure
    pub inline fn init(outputstate: *OutputState, inputstate: *InputState, writer: *std.Io.File.Writer, input_handle: std.Io.File.Handle) Terminal{
        return .{
            .outputstate = outputstate,
            .inputstate = inputstate,
            .writer = writer,
            .inhandle = input_handle
        };
    }
    
    /// Enables raw mode
    pub fn enableRawMode(self: *Terminal) !void{
        if(builtin.os.tag == .windows){
            const win = @import("sys/windows/root.zig");
            var in_state: win.windows.DWORD = 0;

            if(win.winapi.GetConsoleMode(self.inhandle, &in_state) == .FALSE) return error.FailedToEnableRawMode;
            self.inputstate.original_state = in_state;

            const disable = 
                win.winapi.ENABLE_ECHO_INPUT |
                win.winapi.ENABLE_LINE_INPUT |
                win.winapi.ENABLE_PROCESSED_INPUT |
                win.winapi.ENABLE_QUICK_EDIT_MODE;

            if(win.winapi.SetConsoleMode(self.inhandle, (in_state) & ~disable) == .FALSE) return error.FailedToEnableRawMode;
        }else{
            var out_state = std.posix.tcgetattr(self.writer.file.handle) catch return error.FailedToEnableRawMode;
            var in_state = std.posix.tcgetattr(self.inhandle) catch return error.FailedToEnableRawMode;
            self.outputstate.original_state = out_state;
            self.inputstate.original_state = in_state;

            in_state.iflag.IGNBRK = false;
            in_state.iflag.BRKINT = false;
            in_state.iflag.PARMRK = false;
            in_state.iflag.ISTRIP = false;
            in_state.iflag.INLCR = false;
            in_state.iflag.IGNCR = false;
            in_state.iflag.ICRNL = false;
            in_state.iflag.IXON = false;

            out_state.oflag.OPOST = false;

            in_state.lflag.ECHO = false;
            in_state.lflag.ECHONL = false;
            in_state.lflag.ICANON = false;
            in_state.lflag.ISIG = false;
            in_state.lflag.IEXTEN = false;

            in_state.cflag.CSIZE = .CS8;
            in_state.cflag.PARENB = false;

            in_state.cc[@backingInt(std.posix.V.MIN)] = 1;
            in_state.cc[@backingInt(std.posix.V.TIME)] = 0;

            std.posix.tcsetattr(self.writer.file.handle, .FLUSH, out_state) catch return error.FailedToEnableRawMode;
            std.posix.tcsetattr(self.inhandle, .FLUSH, in_state) catch return error.FailedToEnableRawMode;
        }
    }

    /// Disables raw mode
    pub fn disableRawMode(self: *Terminal) !void{
        if(builtin.os.tag == .windows){
            const win = @import("sys/windows/root.zig");
            if(win.winapi.SetConsoleMode(self.inhandle, self.inputstate.original_state) == .FALSE) return error.FailedToEnableRawMode;
        }else{
            std.posix.tcsetattr(self.writer.file.handle, .FLUSH, self.outputstate.original_state) catch return error.FailedToEnableRawMode;
            std.posix.tcsetattr(self.inhandle, .FLUSH, self.inputstate.original_state) catch return error.FailedToEnableRawMode;
        }
    }

    
    /// Clears the terminal screen buffer
    pub fn clear(self: *Terminal, clear_type: ClearType) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                const win = @import("sys/windows/root.zig");

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToClearScreen;
                const winclear = struct{ 
                    fn func(handle: std.Io.File.Handle, loc: win.windows.COORD, cells_to_write: win.windows.DWORD, attribute: win.windows.WORD) !void{
                        var written: win.windows.DWORD = 0;
                        if(win.winapi.FillConsoleOutputCharacterA(handle, ' ', cells_to_write, loc, &written) == .FALSE) return error.FailedToClearScreen;
                        if(win.winapi.FillConsoleOutputAttribute(handle, attribute, cells_to_write, loc, &written) == .FALSE) return error.FailedToClearScreen;
                    }
                }.func;

                self.writer.flush() catch return error.FailedToClearScreen;
                switch(clear_type){
                    .All, .Purge => {
                        winclear(self.writer.file.handle, .{.X = 0, .Y = 0}, @as(u32, @intCast(info.dwSize.X)) * @as(u32, @intCast(info.dwSize.Y)), info.wAttributes) catch return error.FailedToClearScreen;
                    },
                    .FromCursorDown => { 
                        const loc: win.windows.COORD = .{
                            .X = if(info.dwCursorPosition.X > info.dwSize.X)
                                0 
                            else
                                info.dwCursorPosition.X,

                            .Y = if(info.dwCursorPosition.X > info.dwSize.X)
                                info.dwCursorPosition.Y+1 
                            else 
                                info.dwCursorPosition.Y
                        };
                        winclear(self.writer.file.handle, loc, @as(u32, @intCast(info.dwSize.X)) * @as(u32, @intCast(info.dwSize.Y)), info.wAttributes) catch return error.FailedToClearScreen;
                    },
                    .FromCursorUp => {
                        winclear(self.writer.file.handle, .{.X = 0, .Y = 0}, @as(u32, @intCast(info.dwSize.X)) * @as(u32, @intCast(info.dwCursorPosition.Y)) + @as(u32, @intCast(info.dwCursorPosition.X)) + 1, info.wAttributes) catch return error.FailedToClearScreen;
                    },
                    .CurrentRow => {
                        winclear(self.writer.file.handle, .{.X = 0, .Y = info.dwCursorPosition.Y}, @as(u32, @intCast(info.dwSize.X)), info.wAttributes) catch return error.FailedToClearScreen;
                    },
                    .UntilRowEnd => {
                        winclear(self.writer.file.handle, .{.X = info.dwCursorPosition.X, .Y = info.dwCursorPosition.Y}, @as(u32, @intCast(info.dwSize.X)), info.wAttributes) catch return error.FailedToClearScreen;
                    },
                }
                return;
            }
        }
        self.writer.interface.writeAll(
            switch (clear_type) {
                .All => "\x1b[2J",
                .Purge => "\x1b[3J",
                .FromCursorDown => "\x1b[J",
                .FromCursorUp => "\x1b[1J",
                .CurrentRow => "\x1b[2K",
                .UntilRowEnd => "\x1b[K"
            }
        ) catch return error.FailedToClearScreen;
    }

    /// Enter an alternate screen
    pub fn enterAlternateScreen(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                const win = @import("sys/windows/root.zig");
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                if(self.outputstate.original_handle != win.windows.INVALID_HANDLE_VALUE) return;
                const handle: win.windows.HANDLE = win.winapi.CreateConsoleScreenBuffer(
                    win.winapi.GENERIC_READ | win.winapi.GENERIC_WRITE,
                    win.winapi.FILE_SHARE_READ | win.winapi.FILE_SHARE_WRITE,
                    null,
                    win.winapi.CONSOLE_TEXTMODE_BUFFER,
                    null,
                );
                if(handle == win.windows.INVALID_HANDLE_VALUE) return error.FailedToEnterAlternateScreen;

                if(win.winapi.SetConsoleActiveScreenBuffer(handle) == .FALSE) return error.FailedToEnterAlternateScreen;
                const file: std.Io.File = .{
                    .handle = handle,
                    .flags = .{ .nonblocking = false }
                };
                self.outputstate.* = .init(file);
                self.outputstate.original_handle = self.writer.file.handle;
                self.writer.* = .init(file, self.writer.io, self.writer.interface.buffer);
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?1049h") catch return error.FailedToEnterAlternateScreen;
    }

    /// Leave an alternate screen
    pub fn leaveAlternateScreen(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                const win = @import("sys/windows/root.zig");
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                if(self.outputstate.original_handle == win.windows.INVALID_HANDLE_VALUE) return;
                
                if(win.winapi.SetConsoleActiveScreenBuffer(self.outputstate.original_handle) == .FALSE) return error.FailedToLeaveAlternateScreen;

                win.windows.CloseHandle(self.writer.file.handle);
                const file: std.Io.File = .{
                    .handle = self.outputstate.original_handle,
                    .flags = .{ .nonblocking = false }
                };
                self.outputstate.* = .init(file);
                self.writer.* = .init(file, self.writer.io, self.writer.interface.buffer);
                self.outputstate.original_handle = win.windows.INVALID_HANDLE_VALUE;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?1049l") catch return error.FailedToLeaveAlternateScreen;
    }
   
    /// begins a SynchronizedUpdate, Nothing will be drawn to the screen until `endSynchronizedUpdate` is called 
    ///
    /// Note: There is no WinApi fallback for this function
    pub fn beginSynchronizedUpdate(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?2026h") catch return error.FailedToBeginSynchronizedUpdate;
    }

    /// ends a SynchronizedUpdate
    ///
    /// Note: There is no WinApi fallback for this function
    pub fn endSynchronizedUpdate(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?2026l") catch return error.FailedToEndSynchronizedUpdate;
    }

    /// Enables line wrap 
    pub fn enableLineWrap(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                const win = @import("sys/windows/root.zig");
                var mode: u32 = 0;
                if(win.winapi.GetConsoleMode(self.writer.file.handle, &mode) == .FALSE) return error.FailedToEnableLineWrap;
                mode |=win.winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
                
                if(win.winapi.SetConsoleMode(self.writer.file.handle, mode) == .FALSE) return error.FailedToEnableLineWrap;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?7h") catch return error.FailedToEnableLineWrap;
    }

    /// Disables line wrap
    pub fn disableLineWrap(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                const win = @import("sys/windows/root.zig");
                var mode: u32 = 0;
                if(win.winapi.GetConsoleMode(self.writer.file.handle, &mode) == .FALSE) return error.FailedToEnableLineWrap;
                mode &= ~win.winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
                
                if(win.winapi.SetConsoleMode(self.writer.file.handle, mode) == .FALSE) return error.FailedToEnableLineWrap;
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?7l") catch return error.FailedToEnableLineWrap;
    }

    /// scroll up n times 
    pub fn scrollUp(self: *Terminal, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToScrollUp;
                const win = @import("sys/windows/root.zig");
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToScrollUp;
                if(self.outputstate.original_console_state == null)
                    self.outputstate.original_console_state = info;

                if(info.srWindow.Top >= n){
                    info.srWindow.Top-=n;
                    info.srWindow.Bottom-=n;
                }
                if(win.winapi.SetConsoleWindowInfo(self.writer.file.handle, .TRUE, &info.srWindow) == .FALSE) return error.FailedToScrollUp;
                return;
            }
        }
        self.writer.interface.print("\x1b[{}S", .{n}) catch return error.FailedToScrollUp;
    }

    /// scroll down n times 
    pub fn scrollDown(self: *Terminal, n: u16) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToScrollUp;
                const win = @import("sys/windows/root.zig");
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToScrollUp;
                if(self.outputstate.original_console_state == null)
                    self.outputstate.original_console_state = info;
                
                if(info.srWindow.Bottom < info.dwSize.Y - @as(i16, @intCast(n))){
                    info.srWindow.Top+=n;
                    info.srWindow.Bottom+=n;
                }
                if(win.winapi.SetConsoleWindowInfo(self.writer.file.handle, .TRUE, &info.srWindow) == .FALSE) return error.FailedToScrollUp;
                return;
            }
        }
        self.writer.interface.print("\x1b[{}T", .{n}) catch return error.FailedToScrollDown;
    }
    /// Sets the terminal title, on WinAPI fallback the max string len is 512 bytes
    pub fn setTitle(self: *Terminal, title: []const u8) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                const win = @import("sys/windows/root.zig");
                self.writer.flush() catch return error.FailedToSetTitle;

                var utf16_buf: [512:0]u16 = undefined;
                const len = try std.unicode.utf8ToUtf16Le(&utf16_buf, title);
                utf16_buf[len] = 0;

                if(win.winapi.SetConsoleTitleW(utf16_buf[0..len:0]) == .FALSE) return error.FailedToSetTitle;
                return;
            }
        }
        self.writer.interface.print("\x1b]0;{s}\x07", .{title}) catch return error.FailedToSetTitle;
    }   
};
