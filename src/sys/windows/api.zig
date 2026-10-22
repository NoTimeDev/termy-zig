const windows = @import("std").os.windows;
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

pub const ENABLE_PROCESSED_INPUT: u32              = 0x0001;
pub const ENABLE_LINE_INPUT: u32                   = 0x0002;
pub const ENABLE_ECHO_INPUT: u32                   = 0x0004;
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: u32       = 0x0200;
pub const ENABLE_PROCESSED_OUTPUT: u32             = 0x0001;
pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32  = 0x0004;
pub const GENERIC_READ: windows.DWORD              = 0x80000000;
pub const GENERIC_WRITE: windows.DWORD             = 0x40000000;
pub const FILE_SHARE_WRITE: windows.DWORD          = 0x00000002;
pub const FILE_SHARE_READ: windows.DWORD           = 0x00000001;
pub const OPEN_EXISTING: windows.DWORD             = 3;
pub const WAIT_FAILED: windows.DWORD               = 0xFFFFFFFF;
pub const WAIT_OBJECT_0: windows.DWORD             = 0;

