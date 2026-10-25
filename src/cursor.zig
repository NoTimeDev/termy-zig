const std = @import("std");
const builtin = @import("builtin");
const Platform = @import("platform.zig").Platform; 

pub inline fn moveDown(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;
            
            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(info.dwCursorPosition.Y+@as(i16, @intCast(n)))
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    if(n != 0)
        writer.interface.print("\x1b[{}B", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveUp(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;
            
            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.Y))-|n)))
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    if(n != 0)
        writer.interface.print("\x1b[{}A", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveLeft(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;
            
            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(@as(i16, @intCast(@as(u16, @intCast(info.dwCursorPosition.X))-|n))),
                .Y = @intCast(info.dwCursorPosition.Y) 
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }

    if(n != 0)
        writer.interface.print("\x1b[{}D", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveRight(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;
            
            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X+@as(i16, @intCast(n))),
                .Y = @intCast(info.dwCursorPosition.Y) 
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    if(n != 0)
        writer.interface.print("\x1b[{}C", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveToColumn(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;

            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(n-|1),
                .Y = @intCast(info.dwCursorPosition.Y) 
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}G", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveToRow(platform: *Platform, writer: *std.Io.File.Writer, n: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;

            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(win.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == .FALSE) return error.FailedToMoveCursor;
            
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(info.dwCursorPosition.X),
                .Y = @intCast(n-|1) 
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{}d", .{n}) catch return error.FailedToMoveCursor;
}

pub inline fn moveTo(platform: *Platform, writer: *std.Io.File.Writer, x: u16, y: u16) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToMoveCursor;
            if(win.winapi.SetConsoleCursorPosition(writer.file.handle, .{
                .X = @intCast(x-|1),
                .Y = @intCast(y-|1) 
            }) == .FALSE) return error.FailedToMoveCursor;
            return;
        }
    }
    writer.interface.print("\x1b[{};{}H", .{x, y}) catch return error.FailedToMoveCursor;
}

pub inline fn hide(platform: *Platform, writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToHideCursor;
            var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
            if(win.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;
            
            cinfo.bVisible = .FALSE;
            if(win.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToHideCursor;
            return;
        }
    }
    writer.interface.writeAll("\x1b[?25l") catch return error.FailedToHideCursor;
}

pub inline fn show(platform: *Platform, writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToShowCursor;
            var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
            if(win.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;
            
            cinfo.bVisible = .TRUE;
            if(win.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToShowCursor;
            return;
        }
    }
    writer.interface.writeAll("\x1b[?25h") catch return error.FailedToShowCursor;
}

pub inline fn savePosition(platform: *Platform, writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToSavePostion;
            var info: sys.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if(sys.winapi.GetConsoleScreenBufferInfo(writer.file.handle, &info) == sys.windows.BOOL.FALSE) return error.FailedToSavePostion;
           
            platform.saved_cursor_postion = info.dwCursorPosition;
            return;
        }
    }
    writer.interface.writeAll("\x1b[s") catch return error.FailedToSavePostion;
}

pub inline fn restorePosition(platform: *Platform, writer: *std.Io.File.Writer) !void{
    if(builtin.os.tag == .windows){
        const sys = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            writer.flush() catch return error.FailedToRestorePostion;
            if(sys.winapi.SetConsoleCursorPosition(writer.file.handle, platform.saved_cursor_postion) == sys.windows.BOOL.FALSE) return error.FailedToRestorePostion;

            return;
        }
    }
    writer.interface.writeAll("\x1b[s") catch return error.FailedToRestorePostion;
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

pub fn setCursorStyle(platform: *Platform, writer: *std.Io.File.Writer, style: CursorStyle) !void{
    if(builtin.os.tag == .windows){
        const win = @import("sys/windows/root.zig");
        if(!platform.supported.VtOut){
            switch (style) {
                .DefaultUserShape => {
                    writer.flush() catch return error.FailedToSetCursorStyle;
                    var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                    if(win.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    if(platform.default_size != 0)
                        cinfo.dwSize = platform.default_size;
                    if(win.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                },
                .SteadyUnderScore, .BlinkingUnderScore => {
                    writer.flush() catch return error.FailedToSetCursorStyle;
                    var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                    if(win.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    if(platform.default_size == 0)
                        platform.default_size = cinfo.dwSize;
                    
                    cinfo.dwSize = 20;
                    if(win.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                },
                .SteadyBlock, .BlinkingBlock => {
                    writer.flush() catch return error.FailedToSetCursorStyle;
                    var cinfo: win.winapi.CONSOLE_CURSOR_INFO = undefined;
                    if(win.winapi.GetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                    if(platform.default_size == 0)
                        platform.default_size = cinfo.dwSize;
                    
                    cinfo.dwSize = 100;
                    if(win.winapi.SetConsoleCursorInfo(writer.file.handle, &cinfo) == .FALSE) return error.FailedToSetCursorStyle;
                },
                else => {return;}
            }
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
