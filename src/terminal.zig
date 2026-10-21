const Tty = @import("tty.zig").Tty;
const std = @import("std");
const root = @import("root.zig");
const builtin = @import("builtin");
const event = @import("event.zig");
const parser = @import("parser.zig");

pub const WAIT_INDEFINITELY: i32 = -1; 

pub const Terminal = struct {
    tty: Tty,

    pub fn init(io: std.Io, buffer: []u8) !Terminal{
        var tty: Tty = try .init(io, buffer);
        tty.writer.interface.writeAll("\x1b[?1049h") catch return error.FailedToSetTtyAttributes;
        tty.writer.interface.writeAll("\x1b[?1000h")  catch return error.FailedToSetTtyAttributes;
        tty.writer.interface.writeAll("\x1b[?1006h") catch return error.FailedToSetTtyAttributes;
        tty.writer.flush() catch return error.FailedToSetTtyAttributes;
        return .{
            .tty = tty
        };
    }

    pub fn deinit(self: *Terminal) void{
        self.tty.writer.interface.writeAll("\x1b[?1049l") catch {};
        self.tty.writer.interface.writeAll("\x1b[?1006l") catch {};
        self.tty.writer.interface.writeAll("\x1b[?1000l") catch {};
        self.tty.deinit();
    }

    /// Checks if an event is avaible for a certain amount of time
    pub fn poll(self: *Terminal, timeout: std.Io.Duration) !bool{
        return self.tty.poll(@intCast(timeout.toMilliseconds()));
    }
    
    /// Clears all events 
    pub fn clear(self: *Terminal) !void{
        self.tty.clear() catch return error.ErrorStreamCurrupted;
    }

    /// Waits for an event and then returns it
    pub fn read(self: *Terminal) !event.Event{
        var p: parser.Parser = .{};
        while(true){
            _ = self.poll(.fromMilliseconds(-1)) catch return error.ReadFailed;
            var buffer: [64]u8 = undefined;
            const size = self.tty.read(&buffer) catch return error.ReadFailed;
            for(0..size)|i|{
                switch(p.step(buffer[i])){
                    .invalid => {
                        return error.InvalidEventFound;
                    },
                    .event => |e|{
                        return e;
                    },
                    .incomplete => {
                        if(buffer[i] == '\x1b' and size == 1){
                            if(!(self.poll(.fromMilliseconds(20)) catch return error.ReadFailed)){
                                return .{ .Key = .{ .code = .Esc } };
                            }
                        }
                    }
                }
            }
        }
    }
};
