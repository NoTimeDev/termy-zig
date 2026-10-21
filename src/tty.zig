//! Platform-specific implementations of terminal I/O.

const builtin = @import("builtin");
const std = @import("std");

/// Terminal I/O backend for unix 
const UnixTty = struct {
    io: std.Io,
    tty: std.Io.File,
    writer: std.Io.File.Writer,
    original_state: std.posix.termios,

    /// Init's the TTY instance, and sets the terminal to "raw mode"
    pub fn init(io: std.Io, buffer: []u8) !UnixTty{
        const tty = std.Io.Dir.cwd().openFile(io, "/dev/tty", .{
            .mode = .read_write
        }) catch return error.FailedToOpenTty;
       
        const state = std.posix.tcgetattr(tty.handle) catch return error.FailedToSetTtyAttributes;
        var raw = state;

        raw.iflag.IGNBRK = false;
        raw.iflag.BRKINT = false;
        raw.iflag.PARMRK = false;
        raw.iflag.ISTRIP = false;
        raw.iflag.INLCR = false;
        raw.iflag.IGNCR = false;
        raw.iflag.ICRNL = false;
        raw.iflag.IXON = false;

        raw.oflag.OPOST = false;

        raw.lflag.ECHO = false;
        raw.lflag.ECHONL = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;

        raw.cflag.CSIZE = .CS8;
        raw.cflag.PARENB = false;

        raw.cc[@backingInt(std.posix.V.MIN)] = 1;
        raw.cc[@backingInt(std.posix.V.TIME)] = 0;
        std.posix.tcsetattr(tty.handle, .FLUSH, raw) catch return error.FailedToSetTtyAttributes;

        return .{
            .io = io,
            .tty = tty,
            .writer = tty.writer(io, buffer),
            .original_state = state,
        };
    }

    /// Deinits the tty 
    pub fn deinit(self: *UnixTty) void{
        std.posix.tcsetattr(self.tty.handle, .FLUSH, self.original_state) catch {};
        self.writer.flush() catch {};
        self.tty.close(self.io);
    }

    pub fn poll(self: *UnixTty, timeout: i32) !bool{
        var fds = [_]std.posix.pollfd{.{
            .fd = self.tty.handle,
            .events = std.posix.POLL.IN,
            .revents = 0,
        }};
        const ready = std.posix.poll(&fds, timeout) catch return error.PollFailed; 
        if(ready == 0){
            return false;
        }else if((fds[0].revents & std.posix.POLL.IN) != 0){
            return true; 
        }
        unreachable;
    }
    
    pub fn read(self: *UnixTty, buffer: []u8) !usize{
        return self.tty.readStreaming(self.io, &.{buffer});
    }

    pub fn clear(self: *UnixTty) !void{
        try self.tty.setLength(self.io, 0);
    }
};

/// Terminal I/O backend for windows
const WindowsTty = struct {
    const winapi = @import("sys/windows.zig");
    io: std.Io,
    conin: std.Io.File,
    conout: std.Io.File,
    writer: std.Io.File.Writer,
    original_input_state: winapi.windows.DWORD,
    original_output_state: winapi.windows.DWORD,

    /// Init's the TTY, and sets the terminal to "raw mode"
    pub fn init(io: std.Io, buffer: []u8) !WindowsTty{
        const output_handle: winapi.windows.HANDLE = winapi.CreateFileW(
            std.unicode.utf8ToUtf16LeStringLiteral("CONOUT$"),
            winapi.GENERIC_READ | winapi.GENERIC_WRITE,
            winapi.FILE_SHARE_WRITE, 
            null, 
            winapi.OPEN_EXISTING, 
            0,
            null
        );
        if(output_handle == winapi.windows.INVALID_HANDLE_VALUE){
            return error.FailedToOpenTty;
        }

        const input_handle: winapi.windows.HANDLE = winapi.CreateFileW(
            std.unicode.utf8ToUtf16LeStringLiteral("CONIN$"),
            winapi.GENERIC_READ | winapi.GENERIC_WRITE,
            winapi.FILE_SHARE_READ, 
            null, 
            winapi.OPEN_EXISTING, 
            0,
            null
        );

        if(input_handle == winapi.windows.INVALID_HANDLE_VALUE){
            return error.FailedToOpenTty;
        }

        const output: std.Io.File = .{
            .handle = output_handle,
            .flags = .{
                .nonblocking = false 
            }
        };

        const input: std.Io.File = .{
            .handle = input_handle,
            .flags = .{
                .nonblocking = false 
            }
        };

        var original_input: winapi.windows.DWORD = 0;
        var original_output: winapi.windows.DWORD = 0;

        if (winapi.GetConsoleMode(input_handle, &original_input) == winapi.windows.BOOL.FALSE)
            return error.FailedToSetTtyAttributes;

        if (winapi.GetConsoleMode(output_handle, &original_output) == winapi.windows.BOOL.FALSE)
            return error.FailedToSetTtyAttributes;

        const raw_input = (original_input & ~(
            winapi.ENABLE_LINE_INPUT |
            winapi.ENABLE_ECHO_INPUT |
            winapi.ENABLE_PROCESSED_INPUT
        )) | winapi.ENABLE_VIRTUAL_TERMINAL_INPUT;

        const vt_output = original_output | winapi.ENABLE_VIRTUAL_TERMINAL_PROCESSING | winapi.ENABLE_PROCESSED_OUTPUT;

        if (winapi.SetConsoleMode(input_handle, raw_input) == winapi.windows.BOOL.FALSE){
            _ = winapi.SetConsoleMode(input_handle, original_input);
            return error.FailedToSetTtyAttributes;
        }

        if (winapi.SetConsoleMode(output_handle, vt_output) == winapi.windows.BOOL.FALSE) {
            _ = winapi.SetConsoleMode(output_handle, original_output);
            return error.FailedToSetTtyAttributes;
        }

        output.writeStreamingAll(io, "\x1b[?9001h") catch return error.FailedToSetTtyAttributes;
        return .{
            .conin = input,
            .conout = output,
            .io = io,
            .writer = output.writer(io, buffer),
            .original_output_state = original_output,
            .original_input_state = original_input
        };
    }
    
    /// Deinits the tty 
    pub fn deinit(self: *WindowsTty) void{
        self.writer.flush() catch {};
        _ = winapi.SetConsoleMode(self.conin.handle, self.original_input_state);
        _ = winapi.SetConsoleMode(self.conout.handle, self.original_output_state);
        self.conout.close(self.io);
        self.conin.close(self.io);
    }

    pub fn poll(self: *WindowsTty, timeout: i32) !bool{
        return switch(winapi.WaitForSingleObject(self.conin.handle, @bitCast(timeout))){
            winapi.WAIT_FAILED => error.PollFailed,
            winapi.WAIT_OBJECT_0 => true,
            else => false  
        };
    }
    
    pub fn read(self: *WindowsTty, buffer: []u8) !usize{
        return self.conin.readStreaming(self.io, &.{buffer});
    }
    
    pub fn clear(self: *WindowsTty) !void{
        try self.conin.setLength(self.io, 0);
    }
};

pub const Tty = switch (builtin.os.tag) {
    .windows => WindowsTty,
    else => UnixTty 
};
