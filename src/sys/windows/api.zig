const windows = @import("std").os.windows;

pub const CONSOLE_CURSOR_INFO = extern struct { dwSize: windows.DWORD, bVisible: windows.BOOL };

pub const SMALL_RECT = extern struct { Left: windows.WORD, Top: windows.WORD, Right: windows.WORD, Bottom: windows.WORD };

pub const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
    dwSize: windows.COORD,
    dwCursorPosition: windows.COORD,
    wAttributes: windows.WORD,
    srWindow: SMALL_RECT,
    dwMaximumWindowSize: windows.COORD,
};

pub const CHAR = extern union { UnicodeChar: windows.WCHAR, AsciiChar: windows.CHAR };

pub const KEY_EVENT_RECORD = extern struct { bKeyDown: windows.BOOL, wRepeatCount: windows.WORD, wVirtualKeyCode: windows.WORD, wVirtualScanCode: windows.WORD, uChar: CHAR, dwControlKeyState: windows.DWORD };

pub const MOUSE_EVENT_RECORD = extern struct { dwMousePosition: windows.COORD, dwButtonState: windows.DWORD, dwControlKeyState: windows.DWORD, dwEventFlags: windows.DWORD };

pub const WINDOW_BUFFER_SIZE_RECORD = extern struct { dwSize: windows.COORD };

pub const MENU_EVENT_RECORD = extern struct { dwCommandId: windows.UINT };

pub const FOCUS_EVENT_RECORD = extern struct { bSetFocus: windows.BOOL };

pub const INPUT_RECORD = extern struct {
    const EVENT = extern union {
        KeyEvent: KEY_EVENT_RECORD,
        MouseEvent: MOUSE_EVENT_RECORD,
        WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
        MenuEvent: MENU_EVENT_RECORD,
        FocusEvent: FOCUS_EVENT_RECORD,
    };
    EventType: windows.WORD,
    Event: EVENT,
};

pub const CHAR_INFO = extern struct {
    Char: CHAR,
    Attributes: windows.WORD,
};

pub extern "kernel32" fn CreateFileW(lpFileName: windows.LPCWSTR, dwDesiredAccess: windows.DWORD, dwShareMode: windows.DWORD, lpSecurityAttributes: ?*windows.SECURITY_ATTRIBUTES, dwCreationDisposition: windows.DWORD, dwFlagsAndAttributes: windows.DWORD, hTemplateFile: ?windows.HANDLE) callconv(.winapi) windows.HANDLE;

pub extern "kernel32" fn WaitForSingleObject(
    hHandle: windows.HANDLE,
    dwMilliseconds: windows.DWORD,
) callconv(.winapi) windows.DWORD;

pub extern "kernel32" fn GetConsoleMode(hConsoleHandle: windows.HANDLE, lpMode: *windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleMode(hConsoleHandle: windows.HANDLE, dwMode: windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleCursorPosition(hConsoleOutput: windows.HANDLE, dwCursorPosition: windows.COORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleCursorInfo(hConsoleOutput: windows.HANDLE, lpConsoleCursorInfo: *CONSOLE_CURSOR_INFO) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn GetConsoleCursorInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleCursorInfo: *CONSOLE_CURSOR_INFO,
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: windows.HANDLE, lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleTextAttribute(hConsoleOutput: windows.HANDLE, wAttributes: windows.WORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn CreateConsoleScreenBuffer(dwDesiredAccess: windows.DWORD, dwShareMode: windows.DWORD, lpSecurityAttributes: ?*const windows.SECURITY_ATTRIBUTES, dwFlags: windows.DWORD, lpScreenBufferData: ?windows.LPVOID) callconv(.winapi) windows.HANDLE;

pub extern "kernel32" fn SetConsoleActiveScreenBuffer(SetConsoleActiveScreenBuffer: windows.HANDLE) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleTitleW(lpConsoleTitle: windows.LPCWSTR) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn ScrollConsoleScreenBufferW(hConsoleOutput: windows.HANDLE, lpScrollRectangle: *const SMALL_RECT, lpClipRectangle: *const SMALL_RECT, dwDestinationOrigin: windows.COORD, lpFill: *const CHAR_INFO) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleWindowInfo(hConsoleOutput: windows.HANDLE, bAbsolute: windows.BOOL, lpConsoleWindow: *const SMALL_RECT) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn FillConsoleOutputCharacterA(hConsoleOutput: windows.HANDLE, cCharacter: windows.CHAR, nLength: windows.DWORD, dwWriteCoord: windows.COORD, lpNumberOfCharsWritten: *windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn FillConsoleOutputAttribute(hConsoleOutput: windows.HANDLE, wAttribute: windows.WORD, nLength: windows.DWORD, dwWriteCoord: windows.COORD, lpNumberOfAttrsWritten: *windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleOutputCP(
    wCodePageID: windows.UINT,
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleCP(
    wCodePageID: windows.UINT,
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn ReadConsoleInputW(hConsoleInput: windows.HANDLE, lpBuffer: *INPUT_RECORD, nLength: windows.DWORD, lpNumberOfEventsRead: *windows.DWORD) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn GetStdHandle(nStdHandle: windows.DWORD) callconv(.winapi) windows.HANDLE;

pub extern "kernel32" fn SetStdHandle(nStdHandle: windows.DWORD, hHandle: windows.HANDLE) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn FlushConsoleInputBuffer(hConsoleInput: windows.HANDLE) callconv(.winapi) windows.BOOL;

pub extern "user32" fn MapVirtualKeyW(uCode: windows.UINT, uMapType: windows.UINT) callconv(.winapi) windows.UINT;

pub extern "kernel32" fn GetConsoleCP() callconv(.winapi) windows.UINT;
pub extern "kernel32" fn GetConsoleOutputCP() callconv(.winapi) windows.UINT;

pub const MAPVK_VSC_TO_VK_EX: windows.UINT = 3;

pub const FOCUS_EVENT: windows.WORD = 0x0010;
pub const KEY_EVENT: windows.WORD = 0x0001;
pub const MENU_EVENT: windows.WORD = 0x0008;
pub const MOUSE_EVENT: windows.WORD = 0x0002;
pub const WINDOW_BUFFER_SIZE_EVENT: windows.WORD = 0x0004;

pub const ENABLE_PROCESSED_INPUT: u32 = 0x0001;
pub const ENABLE_LINE_INPUT: u32 = 0x0002;
pub const ENABLE_ECHO_INPUT: u32 = 0x0004;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: u32 = 0x0200;
pub const ENABLE_QUICK_EDIT_MODE: u32 = 0x0040;
pub const ENABLE_MOUSE_INPUT: u32 = 0x0010;

pub const ENABLE_WRAP_AT_EOL_OUTPUT: u32 = 0x0002;
pub const ENABLE_PROCESSED_OUTPUT: u32 = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;

pub const GENERIC_READ: windows.DWORD = 0x80000000;
pub const GENERIC_WRITE: windows.DWORD = 0x40000000;
pub const FILE_SHARE_WRITE: windows.DWORD = 0x00000002;
pub const FILE_SHARE_READ: windows.DWORD = 0x00000001;
pub const OPEN_EXISTING: windows.DWORD = 3;
pub const WAIT_FAILED: windows.DWORD = 0xFFFFFFFF;
pub const WAIT_OBJECT_0: windows.DWORD = 0;
pub const CONSOLE_TEXTMODE_BUFFER: windows.DWORD = 1;

pub const COMMON_LVB_UNDERSCORE: u16 = 0x8000;
pub const FOREGROUND_BLUE: u16 = 0x0001;
pub const FOREGROUND_GREEN: u16 = 0x0002;
pub const FOREGROUND_RED: u16 = 0x0004;
pub const FOREGROUND_INTENSITY: u16 = 0x0008;
pub const BACKGROUND_BLUE: u16 = 0x0010;
pub const BACKGROUND_GREEN: u16 = 0x0020;
pub const BACKGROUND_RED: u16 = 0x0040;
pub const BACKGROUND_INTENSITY: u16 = 0x0080;
pub const FG_MASK: u16 = 0x000F;
pub const BG_MASK: u16 = 0x00F0;

pub const FROM_LEFT_1ST_BUTTON_PRESSED: u32 = 0x0001;
pub const RIGHTMOST_BUTTON_PRESSED: u32 = 0x0002;
pub const FROM_LEFT_2ND_BUTTON_PRESSED: u32 = 0x0004;
pub const FROM_LEFT_3RD_BUTTON_PRESSED: u32 = 0x0008;
pub const FROM_LEFT_4TH_BUTTON_PRESSED: u32 = 0x0010;

pub const PRESSED_OR_RELEASED: u32 = 0;
pub const DOUBLE_CLICK: u32 = 0x0002;
pub const MOUSE_HWHEELED: u32 = 0x0008;
pub const MOUSE_MOVED: u32 = 0x0001;
pub const MOUSE_WHEELED: u32 = 0x0004;

pub const CAPSLOCK_ON: u16 = 0x0080;
pub const ENHANCED_KEY: u16 = 0x0100;
pub const LEFT_ALT_PRESSED: u16 = 0x0002;
pub const LEFT_CTRL_PRESSED: u16 = 0x0008;
pub const NUMLOCK_ON: u16 = 0x0020;
pub const RIGHT_ALT_PRESSED: u16 = 0x0001;
pub const RIGHT_CTRL_PRESSED: u16 = 0x0004;
pub const SCROLLLOCK_ON: u16 = 0x0040;
pub const SHIFT_PRESSED: u16 = 0x0010;

pub const VK_LBUTTON: windows.WORD = 0x01;
pub const VK_RBUTTON: windows.WORD = 0x02;
pub const VK_CANCEL: windows.WORD = 0x03;
pub const VK_MBUTTON: windows.WORD = 0x04;
pub const VK_XBUTTON1: windows.WORD = 0x05;
pub const VK_XBUTTON2: windows.WORD = 0x06;
pub const VK_BACK: windows.WORD = 0x08;
pub const VK_TAB: windows.WORD = 0x09;
pub const VK_CLEAR: windows.WORD = 0x0C;
pub const VK_RETURN: windows.WORD = 0x0D;
pub const VK_SHIFT: windows.WORD = 0x10;
pub const VK_CONTROL: windows.WORD = 0x11;
pub const VK_MENU: windows.WORD = 0x12;
pub const VK_PAUSE: windows.WORD = 0x13;
pub const VK_CAPITAL: windows.WORD = 0x14;
pub const VK_KANA: windows.WORD = 0x15;
pub const VK_HANGUL: windows.WORD = 0x15;
pub const VK_IME_ON: windows.WORD = 0x16;
pub const VK_JUNJA: windows.WORD = 0x17;
pub const VK_FINAL: windows.WORD = 0x18;
pub const VK_HANJA: windows.WORD = 0x19;
pub const VK_KANJI: windows.WORD = 0x19;
pub const VK_IME_OFF: windows.WORD = 0x1A;
pub const VK_ESCAPE: windows.WORD = 0x1B;
pub const VK_CONVERT: windows.WORD = 0x1C;
pub const VK_NONCONVERT: windows.WORD = 0x1D;
pub const VK_ACCEPT: windows.WORD = 0x1E;
pub const VK_MODECHANGE: windows.WORD = 0x1F;
pub const VK_SPACE: windows.WORD = 0x20;
pub const VK_PRIOR: windows.WORD = 0x21;
pub const VK_NEXT: windows.WORD = 0x22;
pub const VK_END: windows.WORD = 0x23;
pub const VK_HOME: windows.WORD = 0x24;
pub const VK_LEFT: windows.WORD = 0x25;
pub const VK_UP: windows.WORD = 0x26;
pub const VK_RIGHT: windows.WORD = 0x27;
pub const VK_DOWN: windows.WORD = 0x28;
pub const VK_SELECT: windows.WORD = 0x29;
pub const VK_PRINT: windows.WORD = 0x2A;
pub const VK_EXECUTE: windows.WORD = 0x2B;
pub const VK_SNAPSHOT: windows.WORD = 0x2C;
pub const VK_INSERT: windows.WORD = 0x2D;
pub const VK_DELETE: windows.WORD = 0x2E;
pub const VK_HELP: windows.WORD = 0x2F;
pub const VK_LWIN: windows.WORD = 0x5B;
pub const VK_RWIN: windows.WORD = 0x5C;
pub const VK_APPS: windows.WORD = 0x5D;
pub const VK_SLEEP: windows.WORD = 0x5F;
pub const VK_NUMPAD0: windows.WORD = 0x60;
pub const VK_NUMPAD1: windows.WORD = 0x61;
pub const VK_NUMPAD2: windows.WORD = 0x62;
pub const VK_NUMPAD3: windows.WORD = 0x63;
pub const VK_NUMPAD4: windows.WORD = 0x64;
pub const VK_NUMPAD5: windows.WORD = 0x65;
pub const VK_NUMPAD6: windows.WORD = 0x66;
pub const VK_NUMPAD7: windows.WORD = 0x67;
pub const VK_NUMPAD8: windows.WORD = 0x68;
pub const VK_NUMPAD9: windows.WORD = 0x69;
pub const VK_MULTIPLY: windows.WORD = 0x6A;
pub const VK_ADD: windows.WORD = 0x6B;
pub const VK_SEPARATOR: windows.WORD = 0x6C;
pub const VK_SUBTRACT: windows.WORD = 0x6D;
pub const VK_DECIMAL: windows.WORD = 0x6E;
pub const VK_DIVIDE: windows.WORD = 0x6F;
pub const VK_F1: windows.WORD = 0x70;
pub const VK_F2: windows.WORD = 0x71;
pub const VK_F3: windows.WORD = 0x72;
pub const VK_F4: windows.WORD = 0x73;
pub const VK_F5: windows.WORD = 0x74;
pub const VK_F6: windows.WORD = 0x75;
pub const VK_F7: windows.WORD = 0x76;
pub const VK_F8: windows.WORD = 0x77;
pub const VK_F9: windows.WORD = 0x78;
pub const VK_F10: windows.WORD = 0x79;
pub const VK_F11: windows.WORD = 0x7A;
pub const VK_F12: windows.WORD = 0x7B;
pub const VK_F13: windows.WORD = 0x7C;
pub const VK_F14: windows.WORD = 0x7D;
pub const VK_F15: windows.WORD = 0x7E;
pub const VK_F16: windows.WORD = 0x7F;
pub const VK_F17: windows.WORD = 0x80;
pub const VK_F18: windows.WORD = 0x81;
pub const VK_F19: windows.WORD = 0x82;
pub const VK_F20: windows.WORD = 0x83;
pub const VK_F21: windows.WORD = 0x84;
pub const VK_F22: windows.WORD = 0x85;
pub const VK_F23: windows.WORD = 0x86;
pub const VK_F24: windows.WORD = 0x87;
pub const VK_NUMLOCK: windows.WORD = 0x90;
pub const VK_SCROLL: windows.WORD = 0x91;
pub const VK_LSHIFT: windows.WORD = 0xA0;
pub const VK_RSHIFT: windows.WORD = 0xA1;
pub const VK_LCONTROL: windows.WORD = 0xA2;
pub const VK_RCONTROL: windows.WORD = 0xA3;
pub const VK_LMENU: windows.WORD = 0xA4;
pub const VK_RMENU: windows.WORD = 0xA5;
pub const VK_BROWSER_BACK: windows.WORD = 0xA6;
pub const VK_BROWSER_FORWARD: windows.WORD = 0xA7;
pub const VK_BROWSER_REFRESH: windows.WORD = 0xA8;
pub const VK_BROWSER_STOP: windows.WORD = 0xA9;
pub const VK_BROWSER_SEARCH: windows.WORD = 0xAA;
pub const VK_BROWSER_FAVORITES: windows.WORD = 0xAB;
pub const VK_BROWSER_HOME: windows.WORD = 0xAC;
pub const VK_VOLUME_MUTE: windows.WORD = 0xAD;
pub const VK_VOLUME_DOWN: windows.WORD = 0xAE;
pub const VK_VOLUME_UP: windows.WORD = 0xAF;
pub const VK_MEDIA_NEXT_TRACK: windows.WORD = 0xB0;
pub const VK_MEDIA_PREV_TRACK: windows.WORD = 0xB1;
pub const VK_MEDIA_STOP: windows.WORD = 0xB2;
pub const VK_MEDIA_PLAY_PAUSE: windows.WORD = 0xB3;
pub const VK_LAUNCH_MAIL: windows.WORD = 0xB4;
pub const VK_LAUNCH_MEDIA_SELECT: windows.WORD = 0xB5;
pub const VK_LAUNCH_APP1: windows.WORD = 0xB6;
pub const VK_LAUNCH_APP2: windows.WORD = 0xB7;
pub const VK_OEM_1: windows.WORD = 0xBA;
pub const VK_OEM_PLUS: windows.WORD = 0xBB;
pub const VK_OEM_COMMA: windows.WORD = 0xBC;
pub const VK_OEM_MINUS: windows.WORD = 0xBD;
pub const VK_OEM_PERIOD: windows.WORD = 0xBE;
pub const VK_OEM_2: windows.WORD = 0xBF;
pub const VK_OEM_3: windows.WORD = 0xC0;
pub const VK_GAMEPAD_A: windows.WORD = 0xC3;
pub const VK_GAMEPAD_B: windows.WORD = 0xC4;
pub const VK_GAMEPAD_X: windows.WORD = 0xC5;
pub const VK_GAMEPAD_Y: windows.WORD = 0xC6;
pub const VK_GAMEPAD_RIGHT_SHOULDER: windows.WORD = 0xC7;
pub const VK_GAMEPAD_LEFT_SHOULDER: windows.WORD = 0xC8;
pub const VK_GAMEPAD_LEFT_TRIGGER: windows.WORD = 0xC9;
pub const VK_GAMEPAD_RIGHT_TRIGGER: windows.WORD = 0xCA;
pub const VK_GAMEPAD_DPAD_UP: windows.WORD = 0xCB;
pub const VK_GAMEPAD_DPAD_DOWN: windows.WORD = 0xCC;
pub const VK_GAMEPAD_DPAD_LEFT: windows.WORD = 0xCD;
pub const VK_GAMEPAD_DPAD_RIGHT: windows.WORD = 0xCE;
pub const VK_GAMEPAD_MENU: windows.WORD = 0xCF;
pub const VK_GAMEPAD_VIEW: windows.WORD = 0xD0;
pub const VK_GAMEPAD_LEFT_THUMBSTICK_BUTTON: windows.WORD = 0xD1;
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_BUTTON: windows.WORD = 0xD2;
pub const VK_GAMEPAD_LEFT_THUMBSTICK_UP: windows.WORD = 0xD3;
pub const VK_GAMEPAD_LEFT_THUMBSTICK_DOWN: windows.WORD = 0xD4;
pub const VK_GAMEPAD_LEFT_THUMBSTICK_RIGHT: windows.WORD = 0xD5;
pub const VK_GAMEPAD_LEFT_THUMBSTICK_LEFT: windows.WORD = 0xD6;
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_UP: windows.WORD = 0xD7;
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_DOWN: windows.WORD = 0xD8;
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_RIGHT: windows.WORD = 0xD9;
pub const VK_GAMEPAD_RIGHT_THUMBSTICK_LEFT: windows.WORD = 0xDA;
pub const VK_OEM_4: windows.WORD = 0xDB;
pub const VK_OEM_5: windows.WORD = 0xDC;
pub const VK_OEM_6: windows.WORD = 0xDD;
pub const VK_OEM_7: windows.WORD = 0xDE;
pub const VK_OEM_8: windows.WORD = 0xDF;
pub const VK_OEM_102: windows.WORD = 0xE2;
pub const VK_PROCESSKEY: windows.WORD = 0xE5;
pub const VK_PACKET: windows.WORD = 0xE7;
pub const VK_ATTN: windows.WORD = 0xF6;
pub const VK_CRSEL: windows.WORD = 0xF7;
pub const VK_EXSEL: windows.WORD = 0xF8;
pub const VK_EREOF: windows.WORD = 0xF9;
pub const VK_PLAY: windows.WORD = 0xFA;
pub const VK_ZOOM: windows.WORD = 0xFB;
pub const VK_NONAME: windows.WORD = 0xFC;
pub const VK_PA1: windows.WORD = 0xFD;
pub const VK_OEM_CLEAR: windows.WORD = 0xFE;
