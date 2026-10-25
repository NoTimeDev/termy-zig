const std = @import("std");
const builtin = @import("builtin");

const TRY_FOR_VT_CONSOLE_API: bool = false;
pub const WindowsPlatform = struct {
    const win = @import("sys/windows/root.zig");
    const windows = std.os.windows;

    default_size: windows.DWORD,
    saved_cursor_postion: windows.COORD,
    supported: win.WinSupportedFeatures, 
    pub fn init(file: *const std.Io.File) WindowsPlatform{
        if(TRY_FOR_VT_CONSOLE_API){
            win.enableOutVT(file.handle);
        }
        return .{
            .default_size = 0,
            .saved_cursor_postion = .{
                .X = 0,
                .Y = 0
            },
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
