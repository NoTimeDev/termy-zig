const std = @import("std");
const builtin = @import("builtin");

pub const Cusor = @import("cursor.zig").Cursor; 
pub const Style = @import("style.zig").Style; 
pub const Terminal = @import("terminal.zig").Terminal; 
pub const Input = @import("input.zig").Input;
pub const event = @import("event.zig");

pub const OutputState = @import("state.zig").OutputState;
pub const InputState = @import("state.zig").InputState;

///TODO: @compileError("NORMALIZE INPUT: NO MATTER THE SYSTEM OR FLAGS THE INPUT YOU RECIVE SHOULD BE SOMEWHAT SIMILAR(EG shift + char)");

/// Returns the terminal output file, On windows this is "CONOUT$", on unix systems this is "/dev/tty".
///
/// For TUI applications, prefer this function over standard output.
/// This is especially important on older Windows consoles or when using
/// the WinAPI fallback, where using standard output for alternatescreen
/// operations may cause the original screen contents to be lost.
pub inline fn sysOut(io: std.Io) !std.Io.File{
    return if(builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysOut()
    else 
        @import("sys/unix.zig").sysOut(io);
}

/// Returns the terminal input file, On windows this is "CONIN$", on unix systems this is "/dev/tty".
///
/// When using input on windows, you MUST use sysIN or you will not get events 
pub inline fn sysIn(io: std.Io) !std.Io.File{
    return if(builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysIn()
    else 
        @import("sys/unix.zig").sysOut(io);
}

pub const CodePageInfo = if(builtin.os.tag == .windows)
    struct{i: std.os.windows.UINT, o: std.os.windows.UINT} 
else 
    struct{};
/// This function sets CodePage to UTF-8, this function does nothing on unix systems 
pub fn enableCp() !CodePageInfo{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        const out = win.winapi.GetConsoleOutputCP();
        const in = win.winapi.GetConsoleCP();
        if(out == 0 or in == 0) return error.FailedToEnableCp;
        
        if(win.winapi.SetConsoleCP(65001) == .FALSE) return error.FailedToEnableCp;
        if(win.winapi.SetConsoleOutputCP(65001) == .FALSE) return error.FailedToEnableCp;
        return .{.o = out, .i = in};
    }else{
        return .{};
    }
}

/// This restore the original CodePage
pub fn restoreCp(cp: CodePageInfo) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(win.winapi.SetConsoleCP(cp.i) == .FALSE) return error.FailedToEnableCp;
        if(win.winapi.SetConsoleOutputCP(cp.o) == .FALSE) return error.FailedToEnableCp;
    }
}
