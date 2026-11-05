const std = @import("std");
const builtin = @import("builtin");
const InputState = @import("state.zig").InputState;
const event = @import("event.zig");
const parser = @import("parser.zig");

pub const Input = struct {
    inputstate: *InputState,
    io: std.Io,
    file: std.Io.File,
    buffer: [64]u8 = undefined,
    start: usize = 0,
    len: usize = 0,

    pub fn init(inputstate: *InputState, io: std.Io, file: std.Io.File) Input{
//         if(builtin.os.tag == .windows){
//             const win = @import("sys/windows/root.zig");
//             _ = win.winapi.FlushConsoleInputBuffer(file.handle);
//         }
        return .{
            .io = io,
            .inputstate = inputstate,
            .file = file,
        };
    }


    /// Polls for an event in a given time, true - event is available, false - event is not available
    pub fn poll(self: *Input, timeout: std.Io.Duration) !bool{
        if(builtin.os.tag == .windows){
            const win = @import("sys/windows/root.zig");
            return switch (win.winapi.WaitForSingleObject(self.file.handle, @intCast(timeout.toMilliseconds()))) {
                win.winapi.WAIT_FAILED => error.PollFailed,
                win.winapi.WAIT_OBJECT_0 => true, 
                else => false
            };
        }else{
            var fds = [_]std.posix.pollfd{.{
                .fd = self.file.handle,
                .events = std.posix.POLL.IN,
                .revents = 0,
            }};
            const ready = std.posix.poll(&fds, @intCast(timeout.toMilliseconds())) catch return error.PollFailed; 
            if(ready == 0){
                return false;
            }else if((fds[0].revents & std.posix.POLL.IN) != 0){
                return true; 
            }
            unreachable;
        }
    }

    /// Returns and event, this function will wait until an event is available
    pub fn read(self: *Input) !event.Event{
        if(builtin.os.tag == .windows){
            const win = @import("sys/windows/root.zig");
            var record: win.winapi.INPUT_RECORD = undefined;
            var n: win.windows.DWORD = 0;
            if(win.winapi.ReadConsoleInputW(self.file.handle, &record, 1, &n) == .FALSE) return error.FailedToReadEvent;

            switch (record.EventType) {
                win.winapi.KEY_EVENT => {
                    return .{ .key = win.translateKey(record.Event.KeyEvent)};
                },
                win.winapi.FOCUS_EVENT => {
                    if(record.Event.FocusEvent.bSetFocus == .FALSE){
                        return .FocusLost;
                    }else{
                        return .FocusGained;
                    }
                },
                win.winapi.MOUSE_EVENT => {
                    const e: event.Event = .{ .mouse = win.translateMouse(self.inputstate.mouse_event, record.Event.MouseEvent) };
                    self.inputstate.mouse_event = record.Event.MouseEvent;
                    return e;
                },
                win.winapi.WINDOW_BUFFER_SIZE_EVENT => {
                    return .{ .resize = .{@intCast(record.Event.WindowBufferSizeEvent.dwSize.X), @intCast(record.Event.WindowBufferSizeEvent.dwSize.Y)} };
                },
                else => return event.Event{.key = .{ .code = .Null }},
            }
        }else{
            _ = self.poll(.fromMilliseconds(-1)) catch return error.FailedToReadEvent;
            if(self.len == 0){
                self.len = self.file.readStreaming(self.io, &.{&self.buffer}) catch return error.FailedToReadEvent;
                self.start = 0;
            }
            var p: parser.Parser = .{};
            while (true) {
                if (self.start >= self.len) {
                    _ = self.poll(.fromMilliseconds(-1)) catch return error.FailedToReadEvent;
                    self.len = self.file.readStreaming(self.io, &.{&self.buffer}) catch return error.FailedToReadEvent;
                    self.start = 0;
                }

                const b = self.buffer[self.start];
                const remaining = self.len - self.start;
                self.start += 1;
                
                switch (p.step(b)) {
                    .invalid => return error.InvalidEventFound,
                    .event => |e| return e,
                    .incomplete => {
                        if (b == '\x1b' and remaining == 1) {
                            if (!(self.poll(.fromMilliseconds(20)) catch return error.FailedToReadEvent)){
                                return .{ .key = .{ .code = .Esc } };
                            }
                        }
                        if(b == '[' and p.state == .csi and remaining == 1){
                            if (!(self.poll(.fromMilliseconds(20)) catch return error.FailedToReadEvent)){
                                return .{ .key = .{ .code = .{ .Char = '[' }, .modifier = .{ .Alt = true } } };
                            }
                        }
                    }
                }

            }
            unreachable;
        }
    }
};
