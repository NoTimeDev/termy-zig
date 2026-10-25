const std = @import("std");
const builtin = @import("builtin");

const TRY_FOR_VT_CONSOLE_API: bool = false;
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
    supported: win.WinSupportedFeatures, 
    pub fn init(file: *const std.Io.File) WindowsPlatform{
        if(TRY_FOR_VT_CONSOLE_API){
            win.enableOutVT(file.handle);
        }
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

pub const Platform = if(builtin.os.tag == .windows)
    WindowsPlatform 
else 
    UnixPlatform;
