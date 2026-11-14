const std = @import("std");
const builtin = @import("builtin");
const InputState = @import("state.zig").InputState;
const event = @import("event.zig");
const parser = @import("parser.zig");
const Ring = @import("utils.zig").Ring;
const Tty = @import("root.zig").Tty;
const option = @import("options");

/// This structure allows the user to get events and send queries to the terminal.
///
/// Note: Having more than one `Input` instance can cause undefined behaviour.
pub const Input = struct {
    tty: *Tty,
    buffer: [64]u8 = undefined,
    start: usize = 0,
    len: usize = 0,

    /// Creates a new `Input` structure.
    pub fn init(tty: *Tty) Input {
        if (builtin.os.tag != .windows) {
            const unix = @import("sys/unix.zig");
            if (!unix.inited) unix.initResizeCatch();
        }
        return .{ .tty = tty };
    }

    /// Polls for an event in a given time.
    ///
    /// true - event is available, false - event is not available.
    pub fn poll(self: *Input, timeout: std.Io.Duration) !bool {
        if (builtin.os.tag == .windows) {
            const win = @import("sys/windows/root.zig");
            return switch (win.winapi.WaitForSingleObject(self.tty.in_file.handle, @intCast(timeout.toMilliseconds()))) {
                win.winapi.WAIT_FAILED => error.PollFailed,
                win.winapi.WAIT_OBJECT_0 => true,
                else => false,
            };
        } else {
            return @import("sys/unix.zig").pollfd(self.tty.in_file.handle, @intCast(timeout.toMilliseconds()));
        }
    }

    fn readInternal(self: *Input) !parser.InternalEvent {
        if (builtin.os.tag != .windows) {
            const unix = @import("sys/unix.zig");
            if (unix.resizes.len != 0) {
                const ws = unix.resizes.pop().?;
                return .{ .event = .{ .Resize = .{ ws.rows, ws.columns } } };
            }

            _ = self.poll(.fromMilliseconds(-1)) catch return error.FailedToReadEvent;

            if (self.len == 0) {
                self.len = self.tty.in_file.readStreaming(self.tty.io, &.{&self.buffer}) catch return error.FailedToReadEvent;
                self.start = 0;
            }

            var p: parser.Parser = .{};

            while (true) {
                if (self.start >= self.len) {
                    _ = self.poll(.fromMilliseconds(-1)) catch return error.FailedToReadEvent;
                    self.len = self.tty.in_file.readStreaming(self.tty.io, &.{&self.buffer}) catch return error.FailedToReadEvent;
                    self.start = 0;
                }

                const b = self.buffer[self.start];
                const remaining = self.len - self.start;
                self.start += 1;

                const ievent = p.step(b);
                switch (ievent) {
                    .incomplete => {
                        if (b == '\x1b' and remaining == 1) {
                            if (!(self.poll(.fromMilliseconds(20)) catch return error.FailedToReadEvent)) {
                                return .{ .event = .{ .Key = .{ .code = .Esc } } };
                            }
                        }
                        if (b == '[' and p.state == .csi and remaining == 1) {
                            if (!(self.poll(.fromMilliseconds(20)) catch return error.FailedToReadEvent)) {
                                return .{ .event = .{ .Key = .{ .code = .{ .Char = '[' }, .modifier = .{ .Alt = true } } } };
                            }
                        }
                    },
                    else => return ievent,
                }
            }
            unreachable;
        }
    }

    /// Returns and event, this function will block until an event is available.
    pub fn read(self: *Input) !event.Event {
        if (builtin.os.tag == .windows) {
            const win = @import("sys/windows/root.zig");
            var record: win.winapi.INPUT_RECORD = undefined;
            var n: win.windows.DWORD = 0;
            if (win.winapi.ReadConsoleInputW(self.tty.in_file.handle, &record, 1, &n) == .FALSE) return error.FailedToReadEvent;

            switch (record.EventType) {
                win.winapi.KEY_EVENT => {
                    return .{ .Key = win.translateKey(record.Event.KeyEvent) };
                },
                win.winapi.FOCUS_EVENT => {
                    if (record.Event.FocusEvent.bSetFocus == .FALSE) {
                        return .FocusLost;
                    } else {
                        return .FocusGained;
                    }
                },
                win.winapi.MOUSE_EVENT => {
                    const e: event.Event = .{ .Mouse = win.translateMouse(self.tty.out_writer.file.handle, self.tty.input_state.mouse_event, record.Event.MouseEvent) };
                    self.tty.input_state.mouse_event = record.Event.MouseEvent;
                    return e;
                },
                win.winapi.WINDOW_BUFFER_SIZE_EVENT => {
                    return .{ .Resize = .{ @intCast(record.Event.WindowBufferSizeEvent.dwSize.X +| 1), @intCast(record.Event.WindowBufferSizeEvent.dwSize.Y +| 1) } };
                },
                win.winapi.MENU_EVENT => return .{ .Key = .{ .code = .Null } },
                else => return error.InvalidEventFound,
            }
        } else {
            switch (try self.readInternal()) {
                .invalid => return error.InvalidEventFound,
                .response => return .{ .Key = .{ .code = .Null } },
                else => |e| return e.event,
            }
        }
    }

    /// Querys the terminal position if `eventlist` is null any unrelated events are discarded.
    /// Function returns null if it times out.
    ///
    /// For windows systems the `eventlist` can always be null as events will never be written to the list.
    pub fn queryCursorPosition(self: *Input, timeout: std.Io.Duration, eventlist: ?struct { allocator: std.mem.Allocator, list: *std.ArrayList(event.Event) }) !?struct { x: u16, y: u16 } {
        if (builtin.os.tag == .windows) {
            const win = @import("sys/windows/root.zig");
            var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) return error.FailedToQueryPosition;
            return .{ .x = @intCast(info.dwCursorPosition.X +| 1), .y = @intCast(info.dwCursorPosition.Y +| 1) };
        } else {
            var left = timeout.toMilliseconds();
            self.tty.out_writer.interface.writeAll("\x1b[6n") catch return error.FailedToQueryPosition;
            self.tty.out_writer.flush() catch return error.FailedToQueryPosition;
            while (true) {
                const start = std.Io.Clock.now(.awake, self.tty.io).toMilliseconds();
                if (self.poll(.fromMilliseconds(left)) catch return error.FailedToQueryPosition) {
                    switch (self.readInternal() catch return error.FailedToQueryPosition) {
                        .invalid => return error.InvalidEventFound,
                        .event => |e| {
                            if (eventlist) |elist| {
                                elist.list.append(elist.allocator, e) catch return error.FailedToQueryPosition;
                            }
                        },
                        .response => |r| {
                            switch (r) {
                                .CursorPosition => |c| return .{ .x = c.x, .y = c.y },
                            }
                        },
                        else => unreachable,
                    }
                }
                const end = std.Io.Clock.now(.awake, self.tty.io).toMilliseconds();
                left -= (end - start);
                if (left <= 0) return null;
            }
        }
    }
};
