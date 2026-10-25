const std = @import("std");
const builtin = @import("builtin");
const cursor = @import("cursor.zig");
const Platform = @import("platform.zig").Platform;

pub const CursorStyle = cursor.CursorStyle;

/// Terminal output file, On windows this is "CONOUT$", on unix systems this is "/dev/tty"
pub inline fn sysout(io: std.Io) !std.Io.File{
    return if(builtin.os.tag == .windows)
        @import("sys/windows/root.zig").sysout(io)
    else 
        @import("sys/unix.zig").sysout(io);
}
/// Manages terminal output and provides terminal output control operations
/// 
/// Some operations may flush the writer
pub const OutputTty = struct{
    outwriter: std.Io.File.Writer,
    platform: Platform,
    
    pub fn init(io: std.Io, file: std.Io.File, buffer: []u8) @This(){
        return .{
            .platform = .init(&file),
            .outwriter = .init(file, io, buffer)
        };
    }    
    
    pub fn writer(self: *OutputTty) *std.Io.Writer{
        return &self.outwriter.interface;
    }
    
    // -- Cursor -- 

    /// Moves the cursor n cells down 
    pub fn moveDown(self: *OutputTty, n: u16) !void{
        return cursor.moveDown(&self.platform, &self.outwriter, n);        
    }

    /// Moves the cursor n cells up 
    pub fn moveUp(self: *OutputTty, n: u16) !void{
        return cursor.moveUp(&self.platform, &self.outwriter, n);        
    }
    
    /// Moves the cursor n cells to the left
    pub fn moveLeft(self: *OutputTty, n: u16) !void{
        return cursor.moveLeft(&self.platform, &self.outwriter, n);        
    }

    /// Moves the cursor n cells to the right 
    pub fn moveRight(self: *OutputTty, n: u16) !void{
        return cursor.moveRight(&self.platform, &self.outwriter, n);        
    }

    /// Moves the cursor to column n
    pub fn moveToColumn(self: *OutputTty, n: u16) !void{
        return cursor.moveToColumn(&self.platform, &self.outwriter, n);
    }
    
    /// Moves the cursor to row n
    pub fn moveToRow(self: *OutputTty, n: u16) !void{
        return cursor.moveToRow(&self.platform, &self.outwriter, n);
    }

    /// Moves the cursor to the speficied positon(x, y)
    pub fn moveTo(self: *OutputTty, x: u16, y: u16) !void{
        return cursor.moveTo(&self.platform, &self.outwriter, x, y);
    }
    
    /// Hides the cursor 
    pub fn hide(self: *OutputTty) !void{
        return cursor.hide(&self.platform, &self.outwriter);
    }

    /// Shows the cursor 
    pub fn show(self: *OutputTty) !void{
        return cursor.show(&self.platform, &self.outwriter);
    }

    /// Saves the cursor positon
    pub fn savePosition(self: *OutputTty) !void{
        return cursor.savePosition(&self.platform, &self.outwriter);
    }

    /// Restores the cursor positon
    pub fn restorePosition(self: *OutputTty) !void{
        return cursor.restorePosition(&self.platform, &self.outwriter);
    }

    /// Sets the cursor style.
    /// On Windows, when VT output is unavailable, the following styles may
    /// be supported on some terminals, but support is not guaranteed:
    /// - `SteadyUnderScore`
    /// - `SteadyBlock`
    /// - `BlinkingUnderScore`
    /// - `BlinkingBlock`
    ///
    /// Whether the cursor blinks is terminal dependent
    pub fn setCursorStyle(self: *OutputTty, style: CursorStyle) !void{
        return cursor.setCursorStyle(&self.platform, &self.outwriter, style);
    }
};
