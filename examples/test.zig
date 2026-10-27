const std = @import("std");
const termy = @import("termy");

// This file just has some abitrary test!
pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    var tty: termy.Tty = undefined; 
    tty.init(init.io, try termy.sysout(init.io), &buffer);

    try tty.terminal.scrollDown(9);
    try tty.writer().flush();
}
