const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    // Create a buffered writer
    const stdout = std.Io.File.stdout();
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);
    termy.enableOutVT(stdout);

    try termy.cursor.moveTo(&writer, 20, 20);
    try writer.flush();

    try termy.cursor.hide(&writer);
    try writer.flush();
    

    try termy.cursor.show(&writer);
     // flush output
    try writer.flush();
}
