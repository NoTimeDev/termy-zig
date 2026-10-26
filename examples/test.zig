const std = @import("std");
const termy = @import("termy");

// This file just has some abitrary test!
pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    var out: termy.Tty = undefined;
    out.init(init.io, try termy.sysout(init.io), &buffer);

    try out.terminal.setTitle("Some Title!");
    try out.writer().writeAll("Hello What is up!\n");
    try out.writer().flush();

    try std.Io.sleep(init.io, .fromSeconds(2), .awake);
}
