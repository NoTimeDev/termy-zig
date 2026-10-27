const builtin = @import("builtin");
const std = @import("std");
const OutputState = @import("platform.zig").OutputState;
const options = @import("options");

/// This structure contains functions, which can be used to manipulate how the terminal looks 
pub const Style = struct{
    outputstate: *OutputState,
    writer: *std.Io.File.Writer,

    /// Represents a color
    ///
    /// Note: On windows, if it falls back to the WinAPI,
    /// only the 3/4 bit colors are supported.
    /// AnsiValue and Rgb will do nothing 
    pub const Color = union(enum){
        Reset,

        Black,
        BrightBlack,
        Red,
        BrightRed,
        Green,
        BrightGreen,
        Yellow,
        BrightYellow,
        Blue,
        BrightBlue,
        Magenta,
        BrightMagenta,
        Cyan,
        BrightCyan,
        White,
        BrightWhite,
        
        Rgb: struct{
            r: u8,
            g: u8,
            b: u8,
        },
        AnsiValue: u8,
    };

    /// Represents an attribute
    ///
    /// Note: On windows if fallback occurs,
    /// only Bold, Underlined(unreliable), Dim, Reverse, NormalIntensity, NoUnderline, and NoReverse are supported.
    pub const Attribute = enum{
        Bold,
        Dim,
        Italic,
        
        Underlined,
        DoubleUnderlined,
        Undercurled,
        Underdotted,
        Underdashed,

        SlowBlink,
        RapidBlink,
        
        Reverse,
        
        CrossedOut,

        NormalIntensity,
        NoItalic,
        NoUnderline,
        NoBlink,
        NoReverse,
        NotCrossedOut,
    };

    inline fn getcode(color: Color) u8{
        return switch (color) {   
            .Reset => 39,
           
            .Black => 30,
            .BrightBlack => 90,

            .Red => 31,
            .BrightRed => 91,

            .Green => 32,
            .BrightGreen => 92,

            .Yellow => 33,
            .BrightYellow => 93,

            .Blue => 34,
            .BrightBlue => 94,

            .Magenta => 35,
            .BrightMagenta => 95,
            
            .Cyan => 36,
            .BrightCyan => 96,

            .White => 37,
            .BrightWhite => 97,
            else => unreachable
        };
    }

    const getwindowscode = if(builtin.os.tag == .windows)
        struct {
            pub inline fn getwindowscode(color: Color) std.os.windows.WORD{
                const win = @import("sys/windows/root.zig").winapi;
                return switch (color) {
                    .Black => 0,
                    
                    .Red => win.FOREGROUND_RED,
                    .BrightRed => win.FOREGROUND_RED | win.FOREGROUND_INTENSITY,
                    
                    .Green => win.FOREGROUND_GREEN,
                    .BrightGreen => win.FOREGROUND_GREEN | win.FOREGROUND_INTENSITY,
                    
                    .Blue => win.FOREGROUND_BLUE,
                    .BrightBlue => win.FOREGROUND_BLUE | win.FOREGROUND_INTENSITY,

                    .Yellow => win.FOREGROUND_RED | win.FOREGROUND_GREEN,
                    .BrightYellow => win.FOREGROUND_RED | win.FOREGROUND_GREEN | win.FOREGROUND_INTENSITY,

                    .Magenta => win.FOREGROUND_RED | win.FOREGROUND_BLUE,
                    .BrightMagenta => win.FOREGROUND_RED | win.FOREGROUND_BLUE | win.FOREGROUND_INTENSITY,

                    .Cyan => win.FOREGROUND_GREEN | win.FOREGROUND_BLUE,
                    .BrightCyan => win.FOREGROUND_GREEN | win.FOREGROUND_BLUE | win.FOREGROUND_INTENSITY,

                    .White => win.FOREGROUND_BLUE | win.FOREGROUND_RED | win.FOREGROUND_GREEN,
                    .BrightWhite => win.FOREGROUND_BLUE | win.FOREGROUND_RED | win.FOREGROUND_GREEN | win.FOREGROUND_INTENSITY, 
                    else => unreachable
                };
            }
        }.getwindowscode
    else
        {};

    /// Sets the terminal color 
    pub fn setForegroundColor(self: *Style, color: Color) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToSetForegroundColor;
                if(color == .AnsiValue or color == .Rgb) return;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE)
                    return error.FailedToSetForegroundColor;
                if(self.outputstate.original_console_state == null){
                    self.outputstate.original_console_state = info;
                }
                
                if(color == .Reset){
                    if(win.winapi.SetConsoleTextAttribute(self.writer.file.handle, 
                            (info.wAttributes & ~win.winapi.FG_MASK) | 
                            (self.outputstate.original_console_state.?.wAttributes & win.winapi.FG_MASK)
                    ) == .FALSE)
                        return error.FailedToSetForegroundColor;
                    return;
                }
                if(win.winapi.SetConsoleTextAttribute(self.writer.file.handle, 
                        (info.wAttributes & ~win.winapi.FG_MASK) | getwindowscode(color) 
                ) == .FALSE)
                    return error.FailedToSetForegroundColor;
                return;
            }
        }

        switch(color){
            .Rgb => |rgb| self.writer.interface.print("\x1b[38;2;{};{};{}m", .{rgb.r, rgb.g, rgb.b}) catch return error.FailedToSetForegroundColor,
            .AnsiValue => |ansi| self.writer.interface.print("\x1b[38;5;{}m", .{ansi}) catch return error.FailedToSetForegroundColor,
            else => { 
                self.writer.interface.print("\x1b[{}m", .{getcode(color)}) catch return error.FailedToSetForegroundColor;
            }
        }
    }

    /// Sets the terminal color
    pub fn setBackgroundColor(self: *Style, color: Color) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToSetBackgroundColor;
                if(color == .AnsiValue or color == .Rgb) return;
                
                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE)
                    return error.FailedToSetBackgroundColor;
                if(self.outputstate.original_console_state == null){
                    self.outputstate.original_console_state = info;
                }
                
                if(color == .Reset){
                    if(win.winapi.SetConsoleTextAttribute(self.writer.file.handle, 
                            (info.wAttributes & ~win.winapi.BG_MASK) | 
                            (self.outputstate.original_console_state.?.wAttributes & win.winapi.BG_MASK)
                    ) == .FALSE)
                        return error.FailedToSetBackgroundColor;
                    return;
                }
                if(win.winapi.SetConsoleTextAttribute(self.writer.file.handle, 
                        (info.wAttributes & ~win.winapi.BG_MASK) | (getwindowscode(color) & win.winapi.FG_MASK) << 4
                ) == .FALSE)
                    return error.FailedToSetBackgroundColor;
                return;
            }
        }

        switch(color){
            .Rgb => |rgb| self.writer.interface.print("\x1b[48;2;{};{};{}m", .{rgb.r, rgb.g, rgb.b}) catch return error.FailedToSetBackgroundColor,
            .AnsiValue => |ansi| self.writer.interface.print("\x1b[48;5;{}m", .{ansi}) catch return error.FailedToSetBackgroundColor,
            else => { 
                self.writer.interface.print("\x1b[{}m", .{getcode(color)+10}) catch return error.FailedToSetBackgroundColor;
            }
        }
    }

    /// Sets the terminal underline color
    /// 
    /// Note: There is no windows WinAPI fallback for this,
    /// Non-VT terminals will do nothing
    pub fn setUnderlineColor(self: *Style, color: Color) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            if(options.out == .native or !self.outputstate.supported.VtOut){
                return;
            }
        }
        switch(color){
            .Reset => self.writer.interface.writeAll("\x1b[59m") catch return error.FailedToSetUnderlineColor,
            .Rgb => |rgb| self.writer.interface.print("\x1b[58:2::{}:{}:{}m", .{rgb.r, rgb.g, rgb.b}) catch return error.FailedToSetUnderlineColor,
            .AnsiValue => |ansi| self.writer.interface.print("\x1b[58:5:{}m", .{ansi}) catch return error.FailedToSetUnderlineColor,
            else => {
                const v: u8 = switch (color) {   
                    .Black => 0,
                    .BrightBlack => 8,

                    .Red => 1,
                    .BrightRed => 9,

                    .Green => 2,
                    .BrightGreen => 10,

                    .Yellow => 3,
                    .BrightYellow => 11,

                    .Blue => 4,
                    .BrightBlue => 12,

                    .Magenta => 5,
                    .BrightMagenta => 13,

                    .Cyan => 6,
                    .BrightCyan => 14,

                    .White => 7,
                    .BrightWhite => 15,

                    else => unreachable,
                };
                self.writer.interface.print("\x1b[58;5;{}m", .{v}) catch return error.FailedToSetUnderlineColor;
            }
        }
    }
    
    /// Sets a terminal attribute 
    pub fn setAttribute(self: *Style, attribute: Attribute) !void{
        if(builtin.os.tag == .windows and options.out != .vt){
            const win = @import("sys/windows/root.zig");
            if(options.out == .native or !self.outputstate.supported.VtOut){
                self.writer.flush() catch return error.FailedToSetAttribute;
                switch (attribute) {
                    .Bold, .NormalIntensity, .Underlined, .NoUnderline, .Dim, .Reverse, .NoReverse => {},
                    else => return
                } // Why? Well I dont want to make useless syscalls! 

                var info: win.winapi.CONSOLE_SCREEN_BUFFER_INFO = undefined;
                if(win.winapi.GetConsoleScreenBufferInfo(self.writer.file.handle, &info) == .FALSE)
                    return error.FailedToSetBackgroundColor;
                if(self.outputstate.original_console_state == null){
                    self.outputstate.original_console_state = info;
                }
               
                var attr: u16 = info.wAttributes;
                switch (attribute) {
                    .Bold => attr|=win.winapi.FOREGROUND_INTENSITY,
                    .Dim => attr&=~win.winapi.FOREGROUND_INTENSITY,
                    .Underlined => attr|=win.winapi.COMMON_LVB_UNDERSCORE,
                    .NoUnderline => attr&=~win.winapi.COMMON_LVB_UNDERSCORE,
                    // There are flags for reverse, BUTTTT similar to underscore its unreliable sooo emulate!
                    .Reverse => {
                        if(self.outputstate.reversed) return;
                        self.outputstate.reversed = true;
                        const fg = attr & win.winapi.FG_MASK;
                        const bg = attr & win.winapi.BG_MASK;
                        attr =
                            (attr & ~(win.winapi.FG_MASK | win.winapi.BG_MASK)) |
                            (fg << 4) |
                            (bg >> 4);
                    },
                    .NoReverse => {
                        if(!self.outputstate.reversed) return;
                        self.outputstate.reversed = false;
                        const fg = attr & win.winapi.FG_MASK;
                        const bg = attr & win.winapi.BG_MASK;
                        attr =
                            (attr & ~(win.winapi.FG_MASK | win.winapi.BG_MASK)) |
                            (fg << 4) |
                            (bg >> 4);
                    },
                    .NormalIntensity => {
                        attr = (attr & ~win.winapi.FOREGROUND_INTENSITY) |
                            (self.outputstate.original_console_state.?.wAttributes & win.winapi.FOREGROUND_INTENSITY);
                    },
                    else => {}
                }
                if(win.winapi.SetConsoleTextAttribute(self.writer.file.handle, attr) == .FALSE)
                    return error.FailedToSetBackgroundColor;
                return;
            }
        }
        switch (attribute) {
            .Bold => self.writer.interface.writeAll("\x1b[1m") catch return error.FailedToSetAttribute,
            .Dim => self.writer.interface.writeAll("\x1b[2m") catch return error.FailedToSetAttribute,
            .Italic => self.writer.interface.writeAll("\x1b[3m") catch return error.FailedToSetAttribute,
            .Underlined => self.writer.interface.writeAll("\x1b[4m") catch return error.FailedToSetAttribute,

            .DoubleUnderlined => self.writer.interface.writeAll("\x1b[4:2m") catch return error.FailedToSetAttribute,
            .Undercurled => self.writer.interface.writeAll("\x1b[4:3m") catch return error.FailedToSetAttribute,
            .Underdotted => self.writer.interface.writeAll("\x1b[4:4m") catch return error.FailedToSetAttribute,
            .Underdashed => self.writer.interface.writeAll("\x1b[4:5m") catch return error.FailedToSetAttribute,
            .SlowBlink => self.writer.interface.writeAll("\x1b[5m") catch return error.FailedToSetAttribute,
            .RapidBlink => self.writer.interface.writeAll("\x1b[6m") catch return error.FailedToSetAttribute,
            .Reverse => self.writer.interface.writeAll("\x1b[7m") catch return error.FailedToSetAttribute,
            .CrossedOut => self.writer.interface.writeAll("\x1b[9m") catch return error.FailedToSetAttribute,
            
            .NormalIntensity => self.writer.interface.writeAll("\x1b[22m") catch return error.FailedToSetAttribute,
            .NoItalic => self.writer.interface.writeAll("\x1b[23m") catch return error.FailedToSetAttribute,
            .NoUnderline => self.writer.interface.writeAll("\x1b[24m") catch return error.FailedToSetAttribute,
            .NoBlink => self.writer.interface.writeAll("\x1b[25m") catch return error.FailedToSetAttribute,
            .NoReverse => self.writer.interface.writeAll("\x1b[27m") catch return error.FailedToSetAttribute,
            .NotCrossedOut => self.writer.interface.writeAll("\x1b[29m") catch return error.FailedToSetAttribute,
        }
    }
};
