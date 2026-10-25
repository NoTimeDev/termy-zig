const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    const stdout = std.Io.File.stdout();

    var out: termy.OutputTty = .init(init.io, stdout, &buffer);
   
    try out.moveRight(4);
    try out.writer().writeAll("Hello!\n");
    try out.writer().flush();
}
