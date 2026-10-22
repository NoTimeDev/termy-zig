const std = @import("std");
const winapi = @import("api.zig");
const windows = std.os.windows;

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
