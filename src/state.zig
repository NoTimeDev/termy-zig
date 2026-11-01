const std = @import("std");
const builtin = @import("builtin");

pub const WindowsOutputState = struct {
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
    pub fn init(file: std.Io.File) WindowsOutputState{
        win.enableOutVT(file.handle);
        return .{
            .supported = win.getSupported(file.handle)
        };
    }
};

pub const UnixOutputState = struct {
    original_state: std.posix.termios = undefined,

    pub inline fn init(file: std.Io.File) UnixOutputState{
        _ = file;
        return .{};
    }
};

/// This structure contains os specfic information about the terminal output state
/// Each output file should use its own OutputState instance, sharing a OutputState instance will cause UB 
pub const OutputState = if(builtin.os.tag == .windows)
    WindowsOutputState 
else 
    UnixOutputState;

pub const WindowsInputState = struct {
    const win = @import("sys/windows/root.zig");
    const windows = std.os.windows;
    original_state: windows.DWORD = undefined,
    
    
    pub inline fn init(file: std.Io.File) WindowsInputState{
        _ = file;
        return .{

        };
    }
};

pub const UnixInputState = struct {
    original_state: std.posix.termios = undefined,
    pub inline fn init(file: std.Io.File) UnixInputState{
        _ = file;
        return .{

        };
    }
};

/// This structure contains os specfic information about the terminals input state
/// Each output file should use its own OutputState instance, sharing a OutputState instance will cause UB 
pub const InputState = if(builtin.os.tag == .windows)
    WindowsInputState 
else 
    UnixInputState;

