const std = @import("std");
const builtin = @import("builtin");

pub const Move = struct {
    x: u16,
    y: u16,

    pub fn write_ansi(self: *const @This(), writer: *std.Io.File.Writer) !void{
        try writer.interface.print("\x1b[{};{}H", .{self.x, self.y});
    }

    pub const write_winapi = if(builtin.os.tag == .windows)
        struct {
            fn write_winapi(self: *const Move, writer: *std.Io.File.Writer) !void{
                _ = self; _ = writer;
                @compileError("Move not supported for windows");
            }
        }.write_winapi
    else 
        {};
};
