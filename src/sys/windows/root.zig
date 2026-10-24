const std = @import("std");
pub const winapi = @import("api.zig");
pub const windows = std.os.windows;

pub var current_handle: windows.HANDLE = 0;
pub var supported_features: WinSupportedFeatures = .{}; 
pub var saved_cursor_position: windows.COORD = .{
    .X = 0,
    .Y = 0
};

pub const WinSupportedFeatures = packed struct(u8){
    VtOut: bool = false,
    _: u7 = 0
};

pub inline fn check_handle(handle: windows.HANDLE) void{
    if(currenthandle != handle){
        currenthandle = handle;
        supported_features = getSupported(handle);
    }
}


const testing_windows_api: bool = false;

/// This function is used to get supported features of a terminal to decide whether to use VT or ConsoleApi
pub fn getSupported(handle: windows.HANDLE) WinSupportedFeatures{
    var features: windows.DWORD = 0;
    if(winapi.GetConsoleMode(handle, &features) == windows.BOOL.FALSE)
        return .{};

    var vt: bool = false;
    if(
        (features & winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0 and 
        (features & winapi.ENABLE_PROCESSED_OUTPUT) != 0
    ){
        vt = true;
    }

    if(testing_windows_api){
        return .{};
    }else{
        return .{
            .VtOut = vt
        };
    }
}
 
pub fn enableOutVT(file: std.Io.File) void{
    var out: std.os.windows.DWORD = 0;
    if (winapi.GetConsoleMode(file.handle, &out) == windows.BOOL.FALSE)
        return;

    const vt_output = out | winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING | winapi.ENABLE_PROCESSED_OUTPUT;

    if (winapi.SetConsoleMode(file.handle, vt_output) == windows.BOOL.FALSE) {
        _ = winapi.SetConsoleMode(file.handle, vt_output);
        return;
    }
}

pub fn sysout(io: std.Io) !std.Io.File{
    _ = io;
    const handle = winapi.CreateFileW(
        std.unicode.utf8ToUtf16LeStringLiteral("CONOUT$"), 
        winapi.GENERIC_READ | winapi.GENERIC_WRITE,
        winapi.FILE_SHARE_READ,
        null, 
        winapi.OPEN_EXISTING, 
        0, 
        null
    );
    if(handle == windows.INVALID_HANDLE_VALUE){
        return error.FailedToOpenTty;
    }
    return .{
        .handle = handle,
        .flags = .{ .nonblocking = false }
    };
}

var currenthandle: windows.HANDLE = undefined;
