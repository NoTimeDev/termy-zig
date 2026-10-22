const builtin = @import("builtin");
const std = @import("std");
const sys = switch (builtin.os.tag) {
    .windows => @import("sys/windows/root.zig"),
    else => @import("sys/unix.zig")
};

/// This returns the system's output file, this is different from stdout 
/// On windows this is "CONOUT$" on linux this is "/dev/tty"
pub const sysout = sys.sysout;
pub const cursor = @import("cursor.zig");
pub const style = @import("style.zig");

pub fn queue(writer: *std.Io.File.Writer, comptime commands: anytype) !void{
    const T = @TypeOf(commands);
    switch (@typeInfo(T)) {
        .@"struct" => |info| {
            if (!info.is_tuple) {
                @compileError("expected a tuple of commands");
            }
        },
        .array => {},
        else => @compileError("expected a tuple or array of commands"),
    }

    inline for(commands)|command|{
        const CT = @TypeOf(command);
        if(
            CT != cursor.Move and 
            CT != style.Print and 
            CT != style.Color
        ) @compileError("Unsupported command type");
        if(builtin.os.tag == .windows){
            try command.write_winapi(writer);
        }else{
            try command.write_ansi(writer);
        }
    }
}

pub fn execute(writer: *std.Io.File.Writer, comptime commands: anytype) !void{
    try queue(writer, commands);
    try writer.flush();
}
