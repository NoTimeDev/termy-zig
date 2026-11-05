const event = @import("event.zig");
const std = @import("std");

pub const InternalEvent = union(enum){
    event: event.Event,
    incomplete,
    invalid,
};

pub const Parser = struct {
    const State = enum {
        ground,
        escape,
        csi,
        ss3,
        utf8,
    };

    const Substate = enum {
        none,
        altchar,
    };

    const Paramater = struct {
        value: u16 = 0,
        subparam: [16]u16 = @splat(0),
        subparam_count: usize = 0,
    };

    params: [16]Paramater = @splat(.{}),
    curparam: u16 = 0,
    param_count: usize = 0,
    psub: bool =false,


    utf8: [4]u8 = @splat(0),
    utf8_need: usize = 0,
    utf8_pos: usize = 0,
    state: State = .ground,
    substate: Substate = .none,

    use_srg: bool = false,

    pub fn step(self: *Parser, b: u8) InternalEvent{
        return switch (self.state) {
            .ground => self.parseground(b),
            .csi => self.parsecsi(b),
            .escape => self.parseescape(b),
            .utf8 => self.parseutf8(b),
            .ss3 => self.parsess3(b),
        };
    }

  
    fn parseutf8(self: *Parser, b: u8) InternalEvent{
        if(self.utf8_need == 0){
            self.utf8_need = std.unicode.utf8ByteSequenceLength(b) catch return .invalid;
        }
        self.utf8[self.utf8_pos] = b;
        self.utf8_pos+=1;
        self.utf8_need-=1;
        if(self.utf8_need == 0){
            const bytes: []const u8 = self.utf8[0..self.utf8_pos];
            const utf8 = switch (bytes.len) {
                1 => bytes[0],
                2 => std.unicode.utf8Decode2(bytes[0..2].*) catch return .invalid,
                3 => std.unicode.utf8Decode3(bytes[0..3].*) catch return .invalid,
                4 => std.unicode.utf8Decode4(bytes[0..4].*) catch return .invalid,
                else => return .invalid,
            };
            self.utf8_pos = 0;
            var key = Parser.emitchar(utf8);
            switch (self.substate) {
                .altchar => {
                    self.substate = .none;
                    key.modifier.Alt = true;
                },
                else => {}
            }
            return .{ .event = .{ .key = key } };
        }
        return .incomplete;
    }


    fn parsecsi(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '0'...'9' => {
                self.curparam*=10;
                self.curparam+=b - '0';
                return .incomplete;
            },
            ';' => {
                self.psub = false;
                self.pushParam();
                return .incomplete;
            },
            ':' => {
                self.psub = true;
                self.pushParam();
                return .incomplete;
            },
            '<' => {
                self.use_srg = true;
                return .incomplete;
            },
            0x40...0x4c, 0x4D...0x7e => {
                return self.finishCsi(b);
            },
            else => {
                return .invalid;
            }
        }
    }

    fn parsess3(self: *Parser, b: u8) InternalEvent{
        switch(b){
            'P'...'S' => return self.finishSs3(b),
            else => return .invalid
        }
    }

    fn parseescape(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '[' => {
                self.state = .csi;
                return .incomplete;
            },
            '\x1b' => {
                return .{ .event = .{ .key = .{ .code = .Esc, .modifier = .{ .Alt = true } } } };
            },
            'O' => {
                self.state = .ss3;
                return .incomplete;
            },
            else => {
                self.substate = .altchar;
                self.state = .utf8;
                return self.parseutf8(b);
            }
        }
    }

    fn parseground(self: *Parser, b: u8) InternalEvent{
        switch(b){
            '\x1b' => {
                self.state = .escape;
                return .incomplete;
            },
            0x08, 0x7f => return .{.event = .{ .key = .{ .code = .Backspace } }},
            '\t' => return .{ .event = .{ .key = .{ .code = .Tab } } },
            '\n', '\r' => return .{ .event = .{ .key = .{ .code = .Enter } } },
            0x01...0x07, 0x0b...0x0c, 0x0e...0x1a => return .{ .event = .{ .key = .{ .code = .{ .Char = b + 'a' - 0x01  }, .modifier = .{ .Control = true } } } },
            0x1C...0x1F => return .{ .event = .{ .key = .{ .code = .{ .Char = b + '4' - 0x1C  }, .modifier = .{ .Control = true } } } },
            0x0 => return .{ .event = .{ .key = .{ .code = .{ .Char = ' ' }, .modifier = .{ .Control = true } } } },
            else => {
                self.state = .utf8;
                return self.parseutf8(b);
            }
        }
    }

    fn finishSs3(self: *Parser, b: u8) InternalEvent{
        self.pushParam();
        switch (b) {
            'A' => return .{ .event = .{ .key = .{ .code = .Up} } }, 
            'B' => return .{ .event = .{ .key = .{ .code = .Down} } }, 
            'C' => return .{ .event = .{ .key = .{ .code = .Right} } }, 
            'D' => return .{ .event = .{ .key = .{ .code = .Left} } },
            'F' => return .{ .event = .{ .key = .{ .code = .End } }},
            'H' => return .{ .event = .{ .key = .{ .code = .Home } }},
            
            'P'...'S' => return .{ .event = .{ .key = .{ .code = .{ .F = b - 'P' + 1 } } } },
            else => return .invalid
        }
    }

    fn finishCsi(self: *Parser, b: u8) InternalEvent{
        self.pushParam();
        const mod: event.KeyModifiers = if(self.param_count >= 2) modFromParam(self.params[1].value) else .{};
        switch(b){
            'A' => return .{ .event = .{ .key = .{ .code = .Up, .modifier = mod } } }, 
            'B' => return .{ .event = .{ .key = .{ .code = .Down, .modifier = mod } } }, 
            'C' => return .{ .event = .{ .key = .{ .code = .Right, .modifier = mod } } }, 
            'D' => return .{ .event = .{ .key = .{ .code = .Left, .modifier = mod } } },
            'E', 'G' => return .{ .event = .{ .key = .{ .code = .KeypadBegin, .modifier = mod } } },
            'F' => return .{ .event = .{ .key = .{ .code = .End, .modifier = mod } } },
            'H' => return .{ .event = .{ .key = .{ .code = .Home, .modifier = mod } } },
            'Z' => return .{ .event = .{ .key = .{ .code = .BackTab, .modifier = mod } } },
            'I' => return .{ .event = .FocusGained },
            'O' => return .{.event = .FocusLost },
            '~' => {
                if(self.param_count == 0) return .invalid;
                const v =self.params[0].value;
                const code: event.KeyCode = switch (v) {
                    1, 7 => .Home,
                    2 => .Insert,
                    3 => .Delete,
                    4, 8 => .End,
                    5 => .PageUp,
                    6 => .PageDown,
                    11...15 => .{.F = @intCast(v - 10)},
                    17...21 => .{.F = @intCast(v - 11)},
                    23...26 => .{.F = @intCast(v - 12)},
                    28...29 => .{.F = @intCast(v - 13)},
                    31...34 => .{.F = @intCast(v - 14)},
                    else => return .{ .event = .{ .key = .{ .code = .Null } } }
                };
                return .{ .event = .{ .key = .{ .code = code, .modifier = mod } } };
            },
            'u' => {
                if(self.param_count == 0) return .invalid;

                var key = if(translateFunctionKeyCode(self.params[0].value))|k|
                    k
                else 
                    switch (self.params[0].value) {
                        '\x1b' => event.KeyEvent{.code = .Esc},
                        '\r', '\n' => event.KeyEvent{.code = .Enter},
                        '\t' => event.KeyEvent{.code = .Tab},
                        0x7F => event.KeyEvent{.code = .Backspace},
                        else => event.KeyEvent{.code = .{ .Char = @intCast(self.params[0].value) } },
                    };
                
                const modv: u16 = self.params[1].value-|1;
                key.modifier = .{
                    .Shift = (modv & 1) != 0,
                    .Alt =  (modv & 2) != 0,
                    .Control = (modv & 4) != 0,
                    .Super = (modv & 8) != 0,
                    .Hyper = (modv & 16) != 0,
                    .Meta = (modv & 32) != 0,
                };
                key.state.CapsLock = (modv & 64) != 0;
                key.state.NumLock = (modv & 128) != 0;
                key.kind = switch (self.params[1].subparam[1]) {
                    1 => .Press,
                    2 => .{.Repeat = 1},
                    3 => .Release,
                    else => .Press,
                };
                return .{ .event = .{ .key = key } };
            },
            'M', 'm' =>
                return if(self.use_srg)
                    self.parse_srg_mouse(b)
                else
                    self.parse_rxvt_mouse(),
            else => {
                return .invalid;
            }
        }
    }

    fn parse_srg_mouse(self: *Parser, b: u8) InternalEvent{
        const cb = self.params[0].value;
        var kind: event.MouseEventKind = undefined;

        if((cb & 32) != 0 and (cb & 0b11) == 3){
            kind = .Moved;
        }else if((cb & 64) != 0){
            kind = switch (cb & 0b11) {
                0 => .ScrollUp,
                1 => .ScrollDown,
                2 => .ScrollRight,
                3 => .ScrollLeft,
                else => return .invalid,
            };
        }else{
            const mousebutton: event.MouseButton = switch (cb & 0b11) {
                0 => .Left,
                1 => .Middle,
                2 => .Right,
                else => .Unknown
            };
            if((cb & 32) != 0){
                kind = .{ .Drag = mousebutton };
            }else if(b == 'M'){
                kind = .{ .Down = mousebutton };
            }else{
                kind = .{ .Up = mousebutton };
            }
        }
        return .{ 
            .event = .{ 
                .mouse = .{
                    .modifier = .{
                        .Shift = (cb & 4) != 0,
                        .Alt = (cb & 8) != 0,
                        .Control = (cb & 16) != 0,
                    },
                    .column = self.params[1].value,
                    .row = self.params[2].value,
                    .kind = kind,
                }
            }
        };
    }

    fn parse_rxvt_mouse(self: *Parser) InternalEvent{
        const cb = self.params[0].value - 32;
        var kind: event.MouseEventKind = undefined;

        if ((cb & 64) != 0) {
            kind = switch (cb & 0b11) {
                0 => .ScrollUp,
                1 => .ScrollDown,
                2 => .ScrollLeft,
                3 => .ScrollRight,
                else => return .invalid,
            };
        } else if ((cb & 32) != 0) {
            const button = cb & 0b11;

            if (button == 3) {
                kind = .Moved;
            } else {
                const mousebutton: event.MouseButton = switch (button) {
                    0 => .Left,
                    1 => .Middle,
                    2 => .Right,
                    else => unreachable,
                };

                kind = .{ .Drag = mousebutton };
            }
        } else {
            const button = cb & 0b11;

            if (button == 3) {
                kind = .{ .Up = .Left };
            } else {
                const mousebutton: event.MouseButton = switch (button) {
                    0 => .Left,
                    1 => .Middle,
                    2 => .Right,
                    else => unreachable,
                };

                kind = .{ .Down = mousebutton };
            }
        }
        return .{ 
            .event = .{ 
                .mouse = .{
                    .modifier = .{
                        .Shift = (cb & 4) != 0,
                        .Alt = (cb & 8) != 0,
                        .Control = (cb & 16) != 0,
                    },
                    .column = self.params[1].value,
                    .row = self.params[2].value,
                    .kind = kind,
                }
            }
        };
    }

    fn translateFunctionKeyCode(codepoint: u16) ?event.KeyEvent{
        const keypad_code: ?event.KeyCode = switch (codepoint) {
            57399 => .{ .Char = '0' },
            57400 => .{ .Char = '1' },
            57401 => .{ .Char = '2' },
            57402 => .{ .Char = '3' },
            57403 => .{ .Char = '4' },
            57404 => .{ .Char = '5' },
            57405 => .{ .Char = '6' },
            57406 => .{ .Char = '7' },
            57407 => .{ .Char = '8' },
            57408 => .{ .Char = '9' },
            57409 => .{ .Char = '.' },
            57410 => .{ .Char = '/' },
            57411 => .{ .Char = '*' },
            57412 => .{ .Char = '-' },
            57413 => .{ .Char = '+' },
            57414 => .Enter,
            57415 => .{ .Char = '=' },
            57416 => .{ .Char = ',' },
            57417 => .Left,
            57418 => .Right,
            57419 => .Up,
            57420 => .Down,
            57421 => .PageUp,
            57422 => .PageDown,
            57423 => .Home,
            57424 => .End,
            57425 => .Insert,
            57426 => .Delete,
            57427 => .KeypadBegin,
            else => null,
        };

        if (keypad_code) |code| {
            return .{
                .code = code,
                .state = .{ .KeyPad = true },
            };
        }

        return switch (codepoint) {
            57358 => .{ .code = .CapsLock },
            57359 => .{ .code = .ScrollLock },
            57360 => .{ .code = .NumLock },
            57361 => .{ .code = .PrintScreen },
            57362 => .{ .code = .Pause },
            57363 => .{ .code = .Menu },

            57376...57398 => .{
                .code = .{ .F = @intCast(codepoint - 57363) },
            },

            57428 => .{ .code = .MediaPlay },
            57429 => .{ .code = .MediaPause },
            57430 => .{ .code = .MediaPlayPause },
            57431 => .{ .code = .MediaReverse },
            57432 => .{ .code = .MediaStop },
            57433 => .{ .code = .MediaFastForward },
            57434 => .{ .code = .MediaRewind },
            57435 => .{ .code = .MediaTrackNext },
            57436 => .{ .code = .MediaTrackPrevious },
            57437 => .{ .code = .MediaRecord },
            57438 => .{ .code = .MediaLowerVolume },
            57439 => .{ .code = .MediaRaiseVolume },
            57440 => .{ .code = .MediaMuteVolume },

            57441 => .{ .code = .{ .KeyModifier = .LeftShift } },
            57442 => .{ .code = .{ .KeyModifier = .LeftControl } },
            57443 => .{ .code = .{ .KeyModifier = .LeftAlt } },
            57444 => .{ .code = .{ .KeyModifier = .LeftSuper } },
            57445 => .{ .code = .{ .KeyModifier = .LeftHyper } },
            57446 => .{ .code = .{ .KeyModifier = .LeftMeta } },
            57447 => .{ .code = .{ .KeyModifier = .RightShift } },
            57448 => .{ .code = .{ .KeyModifier = .RightControl } },
            57449 => .{ .code = .{ .KeyModifier = .RightAlt } },
            57450 => .{ .code = .{ .KeyModifier = .RightSuper } },
            57451 => .{ .code = .{ .KeyModifier = .RightHyper } },
            57452 => .{ .code = .{ .KeyModifier = .RightMeta } },
            57453 => .{ .code = .{ .KeyModifier = .IsoLevel3Shift } },
            57454 => .{ .code = .{ .KeyModifier = .IsoLevel5Shift } },

            else => null,
        };    
    } 

    inline fn emitchar(ch: u21) event.KeyEvent{
       return  .{.code = .{ .Char = ch }};
    }

    fn pushParam(self: *Parser) void{
        if(self.param_count < self.params.len){
            const param = &self.params[self.param_count];
            if(self.psub){
                if(param.subparam_count < param.subparam.len){
                    param.subparam[param.subparam_count] = self.curparam;
                    param.subparam_count+=1;
                }
            }else{
                self.params[self.param_count].value = self.curparam;
                self.param_count+=1;
            }
        }
        self.curparam = 0;
    }

    fn modFromParam(param: u16) event.KeyModifiers{
        const m = if (param > 0) param - 1 else 0;
        return .{
            .Shift = m & 1 != 0,
            .Alt = m & 2 != 0,
            .Control = m & 4 != 0,
            .Super = m & 8 != 0,
            .Hyper = m & 16 != 0,
            .Meta = m & 32 != 0,
        };
    }
};
