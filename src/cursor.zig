//! This file provides functions to manipulate the cursor 

const std = @import("std");
const builtin = @import("builtin");

/// Moves cursor n cells down 
pub fn moveDown(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(info.dwCursorPosition.Y+@as(i16, @intCast(n))) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}B", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves cursor n cells up 
pub fn moveUp(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.Y))-|n)))
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}A", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves cursor n cells to the left 
pub fn moveLeft(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.X))-|n))),
                .Y = @intCast(info.dwCursorPosition.Y) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}D", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves cursor n cells to the right 
pub fn moveRight(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X+@as(i16, @intCast(n))),
                .Y = @intCast(info.dwCursorPosition.Y) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}C", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves cursor to column n, this is 1 indexed
pub fn moveToColumn(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(n-|1),
                .Y = @intCast(info.dwCursorPosition.Y)
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}G", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves cursor to row n, this is 1 indexed 
pub fn moveToRow(writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(n-|1) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}d", .{n}) catch return error.FailedToMoveCursor;
}

/// Moves the cursor to the postions specified, this is 1 indexed
pub fn moveTo(writer: *std.Io.File.Writer, x: u16, y: u16) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(x-|1),
                .Y = @intCast(y-|1) 
            }) == sys.windows.BOOL.FALSE)
                return error.FailedToMoveCursor;
            return;
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
            return;
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
            return;
        }
    }
    writer.interface.writeAll("\x1b[?25h") catch return error.FailedToHideCursor;
}

/// Saves cursor postion
/// Note: calling `savePostion` multiple times will overwrite the previously saved postion
/// Only the most recent saved postion can be restored
pub fn savePostion(writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE)
                return error.FailedToSavePostion;
            sys.saved_cursor_position = info.dwCursorPosition;
            return;
        }
    }
    writer.interface.writeAll("\x1b[s") catch return error.FailedToSavePostion;
}

/// Restores cursor postion
/// Note: Only the most recent saved postion can be restored
/// If this function is called before `savePostion` it causes UB in SOME terminals
pub fn restorePostion(writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, sys.saved_cursor_position) == sys.windows.BOOL.FALSE)
                return error.FailedToSavePostion;
            return;
        }
    }
    writer.interface.writeAll("\x1b[u") catch return error.FailedToSavePostion;
}

/// This enum contains options to change the shape of the cursor, and the blinking of the cursor
pub const CursorStyle = enum{
    /// The default cursor shape used in the terminal
    DefaultUserShape,
    
    /// A block cursor shape `■`
    SteadyBlock,
    /// A blinking version of `SteadyBlock`
    BlinkingBlock,
    
    /// An underscore cursor shape `_`
    SteadyUnderScore,
    /// A blinking version of `SteadyUnderScore`
    BlinkingUnderScore,
    
    /// A bar cursor shape `|`
    SteadyBar,
    /// A blinking version of `SteadyBar`
    BlinkingBar,
};

/// Sets the cursor style
/// Note: On windows, if the output does not support VT this function will do nothing 
pub fn setCursorStyle(writer: *std.Io.File.Writer, style: CursorStyle) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        sys.check_handle(writer.file.handle);
        if(!sys.supported_features.VtOut){
            // Hopefully there is some way to fix this!!!
            return;
        }
    }
    const value: u8 = switch (style) {
        .DefaultUserShape => 0,
        
        .BlinkingBlock => 1,
        .SteadyBlock => 2,
        
        .BlinkingUnderScore => 3,
        .SteadyUnderScore => 4,
        
        .BlinkingBar => 5,
        .SteadyBar => 6,
    };
    // Check if this its better to format, or match and use .writeAll 
    writer.interface.print("\x1b[{}\x20q", .{value}) catch return error.FailedToSetCursorStyle;
}
