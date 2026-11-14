const std = @import("std");
pub const winapi = @import("api.zig");
pub const windows = std.os.windows;
pub const options = @import("options");
const event = @import("../../event.zig");
const Lazy = @import("../../utils.zig").Lazy;

pub const WinSupportedFeatures = packed struct(u8) {
    VtOut: bool = false,
    _: u7 = 0,
};

var conIn: Lazy(std.Io.File, struct {
    pub fn init() std.Io.File {
        winapi.cpp();
        const handle = winapi.CreateFileW(std.unicode.utf8ToUtf16LeStringLiteral("CONIN$"), winapi.GENERIC_READ | winapi.GENERIC_WRITE, winapi.FILE_SHARE_READ, null, winapi.OPEN_EXISTING, 0, null);
        return .{ .handle = handle, .flags = .{ .nonblocking = false } };
    }
}.init) = .{};

var conOut: Lazy(std.Io.File, struct {
    pub fn init() std.Io.File {
        const handle = winapi.CreateFileW(std.unicode.utf8ToUtf16LeStringLiteral("CONOUT$"), winapi.GENERIC_READ | winapi.GENERIC_WRITE, winapi.FILE_SHARE_READ, null, winapi.OPEN_EXISTING, 0, null);

        return .{ .handle = handle, .flags = .{ .nonblocking = false } };
    }
}.init) = .{};

pub inline fn getSupported(handle: windows.HANDLE) WinSupportedFeatures {
    if (options.out == .native or options.out == .vt)
        return .{};

    var features: windows.DWORD = 0;
    if (winapi.GetConsoleMode(handle, &features) == windows.BOOL.FALSE)
        return .{};

    var vt: bool = false;
    if ((features & winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0 and
        (features & winapi.ENABLE_PROCESSED_OUTPUT) != 0)
    {
        vt = true;
    }

    return .{ .VtOut = vt };
}

pub fn enableOutVT(handle: windows.HANDLE) void {
    var out: std.os.windows.DWORD = 0;
    if (winapi.GetConsoleMode(handle, &out) == windows.BOOL.FALSE)
        return;

    const vt_output = out | winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING | winapi.ENABLE_PROCESSED_OUTPUT;

    if (winapi.SetConsoleMode(handle, vt_output) == windows.BOOL.FALSE) {
        _ = winapi.SetConsoleMode(handle, vt_output);
        return;
    }
}

pub inline fn sysOut() !std.Io.File {
    const o = conOut.get(.{});
    if (o.handle == windows.INVALID_HANDLE_VALUE) return error.FailedToOpenTty;
    return o;
}

pub inline fn sysIn() !std.Io.File {
    const o = conIn.get(.{});
    if (o.handle == windows.INVALID_HANDLE_VALUE) return error.FailedToOpenTty;
    return o;
}

pub fn translateMouse(outhandle: windows.HANDLE, last_mouse_event: winapi.MOUSE_EVENT_RECORD, record: winapi.MOUSE_EVENT_RECORD) event.MouseEvent {
    const delta: i16 = @bitCast(@as(u16, @truncate(record.dwButtonState >> 16)));
    const kind: event.MouseEventKind = switch (record.dwEventFlags) {
        winapi.PRESSED_OR_RELEASED, winapi.DOUBLE_CLICK => if (record.dwButtonState & winapi.FROM_LEFT_1ST_BUTTON_PRESSED != 0 and
            last_mouse_event.dwButtonState & winapi.FROM_LEFT_1ST_BUTTON_PRESSED == 0) event.MouseEventKind{ .Down = .Left } else if (record.dwButtonState & winapi.FROM_LEFT_1ST_BUTTON_PRESSED == 0 and
            last_mouse_event.dwButtonState & winapi.FROM_LEFT_1ST_BUTTON_PRESSED != 0) event.MouseEventKind{ .Up = .Left } else if (record.dwButtonState & (winapi.RIGHTMOST_BUTTON_PRESSED | winapi.FROM_LEFT_3RD_BUTTON_PRESSED | winapi.FROM_LEFT_4TH_BUTTON_PRESSED) != 0 and
            last_mouse_event.dwButtonState & (winapi.RIGHTMOST_BUTTON_PRESSED | winapi.FROM_LEFT_3RD_BUTTON_PRESSED | winapi.FROM_LEFT_4TH_BUTTON_PRESSED) == 0) event.MouseEventKind{ .Down = .Right } else if (record.dwButtonState & (winapi.RIGHTMOST_BUTTON_PRESSED | winapi.FROM_LEFT_3RD_BUTTON_PRESSED | winapi.FROM_LEFT_4TH_BUTTON_PRESSED) == 0 and
            last_mouse_event.dwButtonState & (winapi.RIGHTMOST_BUTTON_PRESSED | winapi.FROM_LEFT_3RD_BUTTON_PRESSED | winapi.FROM_LEFT_4TH_BUTTON_PRESSED) != 0) event.MouseEventKind{ .Up = .Right } else if (record.dwButtonState & winapi.FROM_LEFT_2ND_BUTTON_PRESSED != 0 and
            last_mouse_event.dwButtonState & winapi.FROM_LEFT_2ND_BUTTON_PRESSED == 0) event.MouseEventKind{ .Down = .Middle } else if (record.dwButtonState & winapi.FROM_LEFT_2ND_BUTTON_PRESSED == 0 and
            last_mouse_event.dwButtonState & winapi.FROM_LEFT_2ND_BUTTON_PRESSED != 0) event.MouseEventKind{ .Up = .Middle } else event.MouseEventKind{ .Down = .Unknown },

        winapi.MOUSE_MOVED => blk: {
            const bttn = if (record.dwButtonState & winapi.FROM_LEFT_1ST_BUTTON_PRESSED != 0) event.MouseButton.Left else if (record.dwButtonState & winapi.FROM_LEFT_2ND_BUTTON_PRESSED != 0) event.MouseButton.Middle else event.MouseButton.Right;
            if (record.dwButtonState == 0) {
                break :blk event.MouseEventKind.Moved;
            } else {
                break :blk event.MouseEventKind{ .Drag = bttn };
            }
        },

        winapi.MOUSE_WHEELED => if (delta < 0)
            event.MouseEventKind.ScrollDown
        else
            event.MouseEventKind.ScrollUp,

        winapi.MOUSE_HWHEELED => if (delta < 0)
            event.MouseEventKind.ScrollLeft
        else
            event.MouseEventKind.ScrollRight,

        else => event.MouseEventKind.Moved,
    };

    var info: winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    const y = if (winapi.GetConsoleScreenBufferInfo(outhandle, &info) == .FALSE)
        0
    else
        @as(u16, @intCast(record.dwMousePosition.Y)) -| info.srWindow.Top;

    return .{ .kind = kind, .column = y, .row = @intCast(record.dwMousePosition.X), .modifier = .{ .Shift = (record.dwControlKeyState & winapi.SHIFT_PRESSED) != 0, .Control = (record.dwControlKeyState &
        (winapi.LEFT_CTRL_PRESSED | winapi.RIGHT_CTRL_PRESSED)) != 0, .Alt = (record.dwControlKeyState &
        (winapi.LEFT_ALT_PRESSED | winapi.RIGHT_ALT_PRESSED)) != 0, .Super = false, .Hyper = false, .Meta = false } };
}

pub fn translateKey(record: winapi.KEY_EVENT_RECORD) event.KeyEvent {
    const code: event.KeyCode =
        vcode: switch (record.wVirtualKeyCode) {
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

            winapi.VK_MEDIA_PLAY_PAUSE => .MediaPlayPause,
            winapi.VK_MEDIA_STOP => .MediaStop,
            winapi.VK_MEDIA_NEXT_TRACK => .MediaTrackNext,
            winapi.VK_MEDIA_PREV_TRACK => .MediaTrackPrevious,
            winapi.VK_VOLUME_DOWN => .MediaLowerVolume,
            winapi.VK_VOLUME_UP => .MediaRaiseVolume,
            winapi.VK_VOLUME_MUTE => .MediaMuteVolume,

            winapi.VK_INSERT => .Insert,
            winapi.VK_DELETE => .Delete,
            winapi.VK_SHIFT, winapi.VK_CONTROL, winapi.VK_MENU => continue :vcode @intCast(winapi.MapVirtualKeyW(record.wVirtualScanCode, winapi.MAPVK_VSC_TO_VK_EX)),

            winapi.VK_LSHIFT => event.KeyCode{ .KeyModifier = .LeftShift },
            winapi.VK_RSHIFT => event.KeyCode{ .KeyModifier = .RightShift },

            winapi.VK_LCONTROL => event.KeyCode{ .KeyModifier = .LeftControl },
            winapi.VK_RCONTROL => event.KeyCode{ .KeyModifier = .RightControl },

            winapi.VK_LMENU => event.KeyCode{ .KeyModifier = .LeftAlt },
            winapi.VK_RMENU => event.KeyCode{ .KeyModifier = .RightAlt },

            winapi.VK_LWIN => event.KeyCode{ .KeyModifier = .LeftSuper },
            winapi.VK_RWIN => event.KeyCode{ .KeyModifier = .RightSuper },

            winapi.VK_F1...winapi.VK_F24 => |k| .{ .F = @as(u8, @intCast(k - winapi.VK_F1 + 1)) },

            else => if (record.uChar.UnicodeChar != 0)
                .{ .Char = @intCast(record.uChar.UnicodeChar) }
            else
                .Null,
        };
    const kind: event.KeyKind = if (record.bKeyDown == .FALSE)
        .Release
    else if (record.wRepeatCount > 1)
        .{ .Repeat = record.wRepeatCount }
    else
        .Press;

    return .{ .code = code, .kind = kind, .state = .{ .CapsLock = (record.dwControlKeyState & winapi.CAPSLOCK_ON) != 0, .NumLock = (record.dwControlKeyState & winapi.NUMLOCK_ON) != 0, .KeyPad = (record.wVirtualKeyCode >= winapi.VK_NUMPAD0 and record.wVirtualKeyCode <= winapi.VK_NUMPAD9) }, .modifier = .{ .Shift = (record.dwControlKeyState & winapi.SHIFT_PRESSED) != 0, .Control = (record.dwControlKeyState &
        (winapi.LEFT_CTRL_PRESSED | winapi.RIGHT_CTRL_PRESSED)) != 0, .Alt = (record.dwControlKeyState &
        (winapi.LEFT_ALT_PRESSED | winapi.RIGHT_ALT_PRESSED)) != 0, .Super = record.wVirtualKeyCode == winapi.VK_LWIN or record.wVirtualKeyCode == winapi.VK_RWIN, .Hyper = false, .Meta = false } };
}
