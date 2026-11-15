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

    paste_buffer: [16 * 1024]u8 = undefined,
    paste_len: usize = 0,
    paste_match: usize = 0,
    paste_active: bool = false,

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
            const unix = @import("sys/unix.zig");
            if (unix.resizes.len != 0) return true;
            return unix.pollfd(self.tty.in_file.handle, @intCast(timeout.toMilliseconds()));
        }
    }

    fn refill(self: *Input) !void {
        const n = self.tty.in_file.readStreaming(self.tty.io, &.{&self.buffer}) catch return error.FailedToReadEvent;
        if (n == 0) return error.EndOfInput;
        self.len = n;
        self.start = 0;
    }

    fn nextByte(self: *Input) !u8 {
        if (self.start >= self.len) try self.refill();
        const b = self.buffer[self.start];
        self.start += 1;
        return b;
    }

    fn takePaste(self: *Input) []const u8 {
        const pasted = self.paste_buffer[0..self.paste_len];
        self.paste_len = 0;
        return pasted;
    }

    /// Consumes bytes while a bracketed paste is active.
    ///
    /// Returns a chunk event when the clipboard is larger than the paste
    /// buffer, `null` when the terminator was found and no content is pending,
    /// and an end-of-input error when the terminal disappears mid paste.
    fn consumePaste(self: *Input) !?parser.InternalEvent {
        const terminator = "\x1b[201~";

        while (true) {
            if (self.paste_len + terminator.len >= self.paste_buffer.len) {
                return .{ .event = .{ .Paste = self.takePaste() } };
            }

            const b = try self.nextByte();
            if (self.paste_match > 0) {
                if (b == terminator[self.paste_match]) {
                    self.paste_match += 1;
                    if (self.paste_match == terminator.len) {
                        self.paste_active = false;
                        self.paste_match = 0;
                        if (self.paste_len == 0) return null;
                        return .{ .event = .{ .Paste = self.takePaste() } };
                    }
                    continue;
                }

                const prefix = terminator[0..self.paste_match];
                @memcpy(self.paste_buffer[self.paste_len..][0..prefix.len], prefix);
                self.paste_len += prefix.len;
                self.paste_match = 0;
                if (b == '\x1b') {
                    self.paste_match = 1;
                    continue;
                }
                self.paste_buffer[self.paste_len] = b;
                self.paste_len += 1;
                continue;
            }

            if (b == '\x1b') {
                self.paste_match = 1;
                continue;
            }
            self.paste_buffer[self.paste_len] = b;
            self.paste_len += 1;
        }
    }

    fn readInternal(self: *Input) !parser.InternalEvent {
        if (builtin.os.tag != .windows) {
            const unix = @import("sys/unix.zig");

            if (unix.resizes.len != 0) {
                const ws = unix.resizes.pop().?;
                return .{ .event = .{ .Resize = .{ .columns = ws.columns, .rows = ws.rows } } };
            }

            var p: parser.Parser = .{};

            while (true) {
                if (self.paste_active) {
                    if (try self.consumePaste()) |pasted| return pasted;
                    p = .{};
                    continue;
                }

                if (self.start >= self.len) try self.refill();

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
                    .paste_begin => {
                        self.paste_active = true;
                        self.paste_match = 0;
                        self.paste_len = 0;
                        p = .{};
                    },
                    .paste_end => p = .{},
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
            if (win.winapi.ReadConsoleInputW(self.tty.in_file.handle, &record, 1, &n) == .FALSE) {
                switch (win.windows.GetLastError()) {
                    .BROKEN_PIPE, .HANDLE_EOF => return error.EndOfInput,
                    else => return error.FailedToReadEvent,
                }
            }

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
                    var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                    if (win.winapi.GetConsoleScreenBufferInfo(self.tty.out_writer.file.handle, &info) == .FALSE) {
                        return .{ .Resize = .{ .columns = @intCast(record.Event.WindowBufferSizeEvent.dwSize.X +| 1), .rows = @intCast(record.Event.WindowBufferSizeEvent.dwSize.Y +| 1) } };
                    }
                    const rows: i32 = @as(i32, info.srWindow.Bottom) - @as(i32, info.srWindow.Top) + 1;
                    const columns: i32 = @as(i32, info.srWindow.Right) - @as(i32, info.srWindow.Left) + 1;
                    return .{ .Resize = .{ .columns = @intCast(@max(columns, 0)), .rows = @intCast(@max(rows, 0)) } };
                },
                win.winapi.MENU_EVENT => return .{ .Key = .{ .code = .Null } },
                else => return error.InvalidEventFound,
            }
        } else {
            switch (try self.readInternal()) {
                .invalid => return error.InvalidEventFound,
                .response => return .{ .Key = .{ .code = .Null } },
                .paste_begin, .paste_end => return error.InvalidEventFound,
                .event => |e| return e,
                .incomplete => unreachable,
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
            const x: i32 = @as(i32, info.dwCursorPosition.X) + 1;
            const y: i32 = @as(i32, info.dwCursorPosition.Y) - @as(i32, info.srWindow.Top) + 1;
            return .{ .x = @intCast(@max(x, 0)), .y = @intCast(@max(y, 0)) };
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
                        .paste_begin, .paste_end => return error.InvalidEventFound,
                        .incomplete => unreachable,
                    }
                }
                const end = std.Io.Clock.now(.awake, self.tty.io).toMilliseconds();
                left -= (end - start);
                if (left <= 0) return null;
            }
        }
    }
};
