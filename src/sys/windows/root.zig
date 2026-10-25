const std = @import("std");
pub const winapi = @import("api.zig");
pub const windows = std.os.windows;

pub const WinSupportedFeatures = packed struct(u8){
    VtOut: bool = false,
    _: u7 = 0
};


pub inline fn getSupported(handle: windows.HANDLE) WinSupportedFeatures{
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

    return .{
        .VtOut = vt
    };
}
 
pub fn enableOutVT(handle: windows.HANDLE) void{
    var out: std.os.windows.DWORD = 0;
    if (winapi.GetConsoleMode(handle, &out) == windows.BOOL.FALSE)
        return;

    const vt_output = out | winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING | winapi.ENABLE_PROCESSED_OUTPUT;

    if (winapi.SetConsoleMode(handle, vt_output) == windows.BOOL.FALSE) {
        _ = winapi.SetConsoleMode(handle, vt_output);
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

