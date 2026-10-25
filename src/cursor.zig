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
