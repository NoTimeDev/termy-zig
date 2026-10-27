const Platform = @import("platform.zig").Platform;
const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");

/// Provides functions to change how the terminal behaves
pub const Terminal = struct {
    platform: *Platform,
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

    /// Enter an alternate screen
    pub fn enterAlternateScreen(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.platform.supported.VtOut){
                const win = @import("sys/windows/root.zig");
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                if(self.platform.original_handle != win.windows.INVALID_HANDLE_VALUE) return;
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
                self.platform.* = .init(&file);
                self.platform.original_handle = self.writer.file.handle;
                self.writer.* = .init(file, self.writer.io, self.writer.interface.buffer);
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?1049h") catch return error.FailedToEnterAlternateScreen;
    }

    /// Leave an alternate screen
    pub fn leaveAlternateScreen(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.platform.supported.VtOut){
                const win = @import("sys/windows/root.zig");
                self.writer.flush() catch return error.FailedToEnterAlternateScreen;
                if(self.platform.original_handle == win.windows.INVALID_HANDLE_VALUE) return;
                
                if(win.winapi.SetConsoleActiveScreenBuffer(self.platform.original_handle) == .FALSE) return error.FailedToLeaveAlternateScreen;

                win.windows.CloseHandle(self.writer.file.handle);
                const file: std.Io.File = .{
                    .handle = self.platform.original_handle,
                    .flags = .{ .nonblocking = false }
                };
                self.platform.* = .init(&file);
                self.writer.* = .init(file, self.writer.io, self.writer.interface.buffer);
                self.platform.original_handle = win.windows.INVALID_HANDLE_VALUE;
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
            if(options.out == .native or !self.platform.supported.VtOut){
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
            if(options.out == .native or !self.platform.supported.VtOut){
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?2026l") catch return error.FailedToEndSynchronizedUpdate;
    }

    /// Enables line wrap 
    pub fn enableLineWrap(self: *Terminal) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.platform.supported.VtOut){
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
            if(options.out == .native or !self.platform.supported.VtOut){
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
            if(options.out == .native or !self.platform.supported.VtOut){
                self.writer.flush() catch return error.FailedToScrollUp;
                const win = @import("sys/windows/root.zig");
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToScrollUp;
                if(self.platform.original_console_state == null)
                    self.platform.original_console_state = info;
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
            if(options.out == .native or !self.platform.supported.VtOut){
                self.writer.flush() catch return error.FailedToScrollUp;
                const win = @import("sys/windows/root.zig");
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE) return error.FailedToScrollUp;
                if(self.platform.original_console_state == null)
                    self.platform.original_console_state = info;
                
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
            if(options.out == .native or !self.platform.supported.VtOut){
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
    
    /// Clears the terminal screen buffer
    pub fn clear(self: *Terminal, clear_type: ClearType) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.platform.supported.VtOut){
                return;
            }
        }
        switch (clear_type) {
            else => {}
        }
    }
};
