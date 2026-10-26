const Platform = @import("platform.zig").Platform;
const std = @import("std");
const builtin = @import("builtin");

/// Provides functions to change how the terminal behaves
pub const Terminal = struct {
    platform: *Platform,
    writer: *std.Io.File.Writer,

    /// Enter an alternate screen
    pub fn enterAlternateScreen(self: *Terminal) !void{
        if(builtin.os.tag == .windows){
            if(!self.platform.supported.VtOut){
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
        if(builtin.os.tag == .windows){
            if(!self.platform.supported.VtOut){
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
        if(builtin.os.tag == .windows){
            if(!self.platform.supported.VtOut){
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?2026h") catch return error.FailedToBeginSynchronizedUpdate;
    }

    /// ends a SynchronizedUpdate
    ///
    /// Note: There is no WinApi fallback for this function
    pub fn endSynchronizedUpdate(self: *Terminal) !void{
        if(builtin.os.tag == .windows){
            if(!self.platform.supported.VtOut){
                return;
            }
        }
        self.writer.interface.writeAll("\x1b[?2026l") catch return error.FailedToEndSynchronizedUpdate;
    }
    
    /// Sets the terminal title, on WinAPI fallback the max string len is 512 bytes
    pub fn setTitle(self: *Terminal, title: []const u8) !void{
        if(builtin.os.tag == .windows){
            if(!self.platform.supported.VtOut){
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
