const std = @import("std");
const builtin = @import("builtin");

const TRY_FOR_VT_CONSOLE_API: bool = true;
pub const WindowsPlatform = struct {
    const win = @import("sys/windows/root.zig");
    const windows = std.os.windows;

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
