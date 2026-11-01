const std = @import("std");
pub const winapi = @import("api.zig");
pub const windows = std.os.windows;
pub const options = @import("options");

pub const WinSupportedFeatures = packed struct(u8){
    VtOut: bool = false,
    _: u7 = 0
};
pub inline fn getSupported(handle: windows.HANDLE) WinSupportedFeatures{
    if(options.out == .native or options.out == .vt)
        return .{};

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

pub inline fn sysOut() !std.Io.File{
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

pub inline fn sysIn() !std.Io.File{
    const handle = winapi.CreateFileW(
        std.unicode.utf8ToUtf16LeStringLiteral("CONIN$"), 
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

const event = @import("../../event.zig");
pub fn translateKey(record: winapi.KEY_EVENT_RECORD) event.KeyEvent{
    const code: event.KeyCode = 
        switch (record.wVirtualKeyCode) {
            winapi.VK_BACK => .Backspace,
            winapi.VK_TAB => .Tab,
            winapi.VK_RETURN => .Enter,
            winapi.VK_ESCAPE => .Esc,

            winapi.VK_PRIOR => .PageUp,
            winapi.VK_NEXT => .PageDown,
            winapi.VK_END => .End,
            winapi.VK_HOME => .Home,

            winapi.VK_LEFT => .Left,
            winapi.VK_UP => .Up,
            winapi.VK_RIGHT => .Right,
            winapi.VK_DOWN => .Down,

            winapi.VK_INSERT => .Insert,
            winapi.VK_DELETE => .Delete,

            winapi.VK_SHIFT, winapi.VK_CAPITAL => event.KeyCode{ .KeyModifier = .{ .Shift = true } },
            winapi.VK_CONTROL => event.KeyCode{ .KeyModifier = .{ .Control = true } },
            winapi.VK_MENU => event.KeyCode{ .KeyModifier = .{ .Alt = true } },
            winapi.VK_F1...winapi.VK_F24 => |k|
                .{ .F = @as(u8, @intCast(k - winapi.VK_F1 + 1)) },

            else => if(record.uChar.UnicodeChar != 0)
                    .{ .Char = @intCast(record.uChar.UnicodeChar) }
                else 
                    .{ .Char = @intCast(record.wVirtualKeyCode) },
        };
    return .{
        .code = code,
    };
} 
