const windows = @import("std").os.windows;

pub const CONSOLE_CURSOR_INFO = extern struct{
    dwSize: windows.DWORD,
    bVisible: windows.BOOL
};

pub const SMALL_RECT = extern struct{
    Left: windows.WORD,
    Top: windows.WORD,
    Right: windows.WORD,
    Bottom: windows.WORD
};

pub const CONSOLE_SCREEN_BUFFER_INFO  = extern struct{
  dwSize: windows.COORD,
  dwCursorPosition: windows.COORD,
  wAttributes: windows.WORD,
  srWindow: SMALL_RECT,
  dwMaximumWindowSize: windows.COORD,
};

pub extern "kernel32" fn CreateFileW(
    lpFileName: windows.LPCWSTR,
    dwDesiredAccess: windows.DWORD,
    dwShareMode: windows.DWORD,
    lpSecurityAttributes: ?*windows.SECURITY_ATTRIBUTES,
    dwCreationDisposition: windows.DWORD,
    dwFlagsAndAttributes: windows.DWORD,
    hTemplateFile: ?windows.HANDLE
) callconv(.winapi) windows.HANDLE;

pub extern "kernel32" fn WaitForSingleObject(
    hHandle: windows.HANDLE,
    dwMilliseconds: windows.DWORD, 
) callconv(.winapi) windows.DWORD;

pub extern "kernel32" fn GetConsoleMode(
    hConsoleHandle: windows.HANDLE,
    lpMode: *windows.DWORD
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleMode(
    hConsoleHandle: windows.HANDLE,
    dwMode: windows.DWORD
) callconv(.winapi) windows.BOOL;
 
pub extern "kernel32" fn SetConsoleCursorPosition(
    hConsoleOutput: windows.HANDLE,
    dwCursorPosition: windows.COORD  
) callconv(.winapi) windows.BOOL;


pub extern "kernel32" fn SetConsoleCursorInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleCursorInfo: *CONSOLE_CURSOR_INFO
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn GetConsoleCursorInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleCursorInfo: *CONSOLE_CURSOR_INFO,
) callconv(.winapi) windows.BOOL; 

pub extern "kernel32" fn GetConsoleScreenBufferInfo(
    hConsoleOutput: windows.HANDLE,
    lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn SetConsoleTextAttribute(
    hConsoleOutput: windows.HANDLE,
    wAttributes: windows.WORD
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn CreateConsoleScreenBuffer(
  dwDesiredAccess: windows.DWORD,
  dwShareMode: windows.DWORD,
  lpSecurityAttributes: ?*const windows.SECURITY_ATTRIBUTES,
  dwFlags: windows.DWORD,
  lpScreenBufferData: ?windows.LPVOID
) callconv(.winapi) windows.HANDLE;

pub extern "kernel32" fn SetConsoleActiveScreenBuffer(
    SetConsoleActiveScreenBuffer: windows.HANDLE
) callconv(.winapi) windows.BOOL;

pub const ENABLE_PROCESSED_INPUT: u32                  = 0x0001;
pub const ENABLE_LINE_INPUT: u32                       = 0x0002;
pub const ENABLE_ECHO_INPUT: u32                       = 0x0004;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: u32           = 0x0200;
pub const ENABLE_PROCESSED_OUTPUT: u32                 = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32      = 0x0004;

pub const GENERIC_READ: windows.DWORD                  = 0x80000000;
pub const GENERIC_WRITE: windows.DWORD                 = 0x40000000;
pub const FILE_SHARE_WRITE: windows.DWORD              = 0x00000002;
pub const FILE_SHARE_READ: windows.DWORD               = 0x00000001;
pub const OPEN_EXISTING: windows.DWORD                 = 3;
pub const WAIT_FAILED: windows.DWORD                   = 0xFFFFFFFF;
pub const WAIT_OBJECT_0: windows.DWORD                 = 0;
pub const CONSOLE_TEXTMODE_BUFFER: windows.DWORD       = 1;

pub const COMMON_LVB_UNDERSCORE: u16 = 0x8000;
pub const FOREGROUND_BLUE: u16                         = 0x0001;
pub const FOREGROUND_GREEN: u16                        = 0x0002;
pub const FOREGROUND_RED: u16                          = 0x0004;
pub const FOREGROUND_INTENSITY: u16                    = 0x0008;
pub const BACKGROUND_BLUE: u16                         = 0x0010;
pub const BACKGROUND_GREEN: u16                        = 0x0020;
pub const BACKGROUND_RED: u16                          = 0x0040;
pub const BACKGROUND_INTENSITY: u16                    = 0x0080;
pub const FG_MASK: u16                                 = 0x000F;
pub const BG_MASK: u16                                 = 0x00F0;
