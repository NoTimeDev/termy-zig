const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    // Create a buffered writer 
    var writer: std.Io.File.Writer = .init(std.Io.File.stdout(), init.io, &buffer);

    // execute automatically flushes 
    try termy.execute(&writer, .{
        termy.style.Color{.Red = {}},
        termy.style.Print{.msg = "Some Error!\n"},
        termy.style.Color{.Reset = {}},
    });
}
