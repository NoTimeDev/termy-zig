const builtin = @import("builtin");
const std = @import("std");

pub const Color = union(enum){
    Red,
    Reset,
    Rgb: struct{r: u8, g: u8, b: u8},

    pub fn write_ansi(self: *const @This(), writer: *std.Io.File.Writer) !void{
        switch (self.*) {
            .Red => try writer.interface.writeAll("\x1b[31m"),
            .Reset => try writer.interface.writeAll("\x1b[0m"),
            .Rgb => |c|{
                try writer.interface.print("\x1b[38;2;{};{};{}m", .{c.r, c.g, c.b});
            }
        }
    }

    pub const write_winapi = if(builtin.os.tag == .windows)
        write_ansi
    else
        {};
};



pub const Print = struct {
    msg: []const u8,

    pub fn write_ansi(self: *const @This(), writer: *std.Io.File.Writer) !void{
        try writer.interface.writeAll(self.msg);
    }

    pub const write_winapi = if(builtin.os.tag == .windows)
        write_ansi    
    else 
        {};
};
