// Based on https://vt100.net/emu/dec_ansi_parser

const event = @import("event.zig");
const std = @import("std");

pub const InternalEvent = union(enum){
    event: event.Event,
    incomplete,
    invalid
};

pub const Parser = struct {
    const State = enum {
        ground,
        escape,
        csi,
        ss3,
        mouse,
        utf8
    };
    params: [16]u16 = @splat(0),
    curparam: usize = 0,
    param_count: usize = 0,
    utf8: [4]u8 = @splat(0),
    utf8_len: usize = 0,
    state: State = .ground,

    pub fn step(self: *Parser, b: u8) InternalEvent{
        return switch (self.state) {
            .ground => self.parseground(b),
            .csi => self.parsecsi(b),
            .escape => self.parseescape(b),
            else => unreachable
        };
    }

    fn parsecsi(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '0'...'9' => {
                self.params[self.curparam]*=10;
                self.params[self.curparam]+=b;
                return .incomplete;
            },
            'A' => return .{ .event = .{ .Key = .{ .code = .Up } } }, 
            'B' => return .{ .event = .{ .Key = .{ .code = .Down } } }, 
            'C' => return .{ .event = .{ .Key = .{ .code = .Right } } }, 
            'D' => return .{ .event = .{ .Key = .{ .code = .Left } } },
            else => {
                return .invalid;
            }
        }
    }

    fn parseescape(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '[' => {
                self.state = .csi;
                return .incomplete;
            },
            else => {
                return .invalid;
            }
        }
    }

    fn parseground(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '\x1b' => {
                self.state = .escape;
                return .incomplete;
            },
            0x08, 0x7f => return .{.event = .{ .Key = .{ .code = .Backspace } }},
            0x09 => return .{ .event = .{ .Key = .{ .code = .Tab } } },
            0x0a, 0x0d => return .{ .event = .{ .Key = .{ .code = .Enter } } },
            0x01...0x07, 0x0b...0x0c, 0x0e...0x1a => return .{ .event = .{ .Key = .{ .code = .{ .Char = b + 'a' - 0x01  }, .modifier = .Control } } },
            else => {
                const need = std.unicode.utf8ByteSequenceLength(b) catch return .invalid;
                if(need == 1) return Parser.emitchar(b);
                return .incomplete;
            }
        }
    }

    fn emitchar(ch: u8) InternalEvent{
        return if(ch >= 'A' and ch <= 'Z')
            .{ .event = .{ .Key = .{ .code = .{ .Char = ch }, .modifier = .Shift } } }
        else 
            .{ .event = .{ .Key = .{ .code = .{ .Char = ch } } }};
    }
};
