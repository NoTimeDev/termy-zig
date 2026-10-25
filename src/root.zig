//! Root module for termy! 

const std = @import("std");
const builtin = @import("builtin");
const cursor = @import("cursor.zig");
const Platform = @import("platform.zig").Platform;

/// Terminal output file, On windows this is "CONOUT$" on unix systems this is "/dev/tty"
pub const sysout = if(builtin.os.tag == .windows)
    @import("sys/windows/root.zig").sysout
else 
    @import("sys/unix.zig").sysout;

pub const OutputTty = struct{
    outwriter: std.Io.File.Writer,
    platform: Platform,
    
    pub fn init(io: std.Io, file: std.Io.File, buffer: []u8) @This(){
        return .{
            .platform = .init(&file),
            .outwriter = .init(file, io, buffer)
        };
    }    
    
    pub fn writer(self: *@This()) *std.Io.Writer{
        return &self.outwriter.interface;
    }
    
    // -- Cursor -- 

    /// Moves the cursor n cells down 
    pub fn moveDown(self: *@This(), n: u16) !void{
        return cursor.moveDown(&self.platform, &self.outwriter, n);        
    }

    /// Moves the cursor n cells up 
    pub fn moveUp(self: *@This(), n: u16) !void{
        return cursor.moveUp(&self.platform, &self.outwriter, n);        
    }
    
    /// Moves the cursor n cells to the left
    pub fn moveLeft(self: *@This(), n: u16) !void{
        return cursor.moveLeft(&self.platform, &self.outwriter, n);        
    }

    /// Moves the cursor n cells to the right 
    pub fn moveRight(self: *@This(), n: u16) !void{
        return cursor.moveRight(&self.platform, &self.outwriter, n);        
    }
};
