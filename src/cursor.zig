//! This file provides functions to manipulate the cursor 

const std = @import("std");
const builtin = @import("builtin");

/// Moves the cursor to the postions specified
pub fn moveTo(writer: *std.Io.File.Writer, x: u16, y: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(x),
                .Y = @intCast(y) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
        }
    }
    writer.interface.print("\x1b[{};{}H", .{x, y}) catch return error.FailedToMoveCursor;
}

/// Hides the cursor 
pub fn hide(writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var cinfo: sys.winapi.CONSOLE_CURSOR_INFO = undefined;
            if(sys.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == sys.windows.BOOL.FALSE)
                return error.FailedToHideCursor;
            cinfo.bVisible = sys.windows.BOOL.FALSE;
            if(sys.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == sys.windows.BOOL.FALSE)
                return error.FailedToHideCursor;
        }
    }
    writer.interface.writeAll("\x1b[?25l") catch return error.FailedToHideCursor;
}

/// Shows the cursor 
pub fn show(writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var cinfo: sys.winapi.CONSOLE_CURSOR_INFO = undefined;
            if(sys.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == sys.windows.BOOL.FALSE)
                return error.FailedToHideCursor;
            cinfo.bVisible = sys.windows.BOOL.TRUE;
            if(sys.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == sys.windows.BOOL.FALSE)
                return error.FailedToHideCursor;
        }
    }
    writer.interface.writeAll("\x1b[?25h") catch return error.FailedToHideCursor;
}
