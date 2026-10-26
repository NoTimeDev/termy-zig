const std = @import("std");
const builtin = @import("builtin");

pub const WindowsPlatform = struct {
    const win = @import("sys/windows/root.zig");
    const windows = std.os.windows;

    default_size: windows.DWORD = 0,
    saved_cursor_postion: windows.COORD = .{
        .X = 0,
        .Y = 0,
    },
    original_console_state: ?win.winapi.CONSOLE_SCREEN_BUFFER_INFO = null,
    reversed: bool = false,
    original_handle: windows.HANDLE = windows.INVALID_HANDLE_VALUE,
    supported: win.WinSupportedFeatures,
    pub fn init(file: *const std.Io.File) WindowsPlatform{
        win.enableOutVT(file.handle);
        return .{
            .supported = win.getSupported(file.handle)
        };
    }
};

pub const UnixPlatform = struct {
    pub inline fn init(file: *const std.Io.File) UnixPlatform{
        _ = file;
        return .{};
    }
};

/// This structure contains os specfic information about the terminal
pub const Platform = if(builtin.os.tag == .windows)
    WindowsPlatform 
else 
    UnixPlatform;
