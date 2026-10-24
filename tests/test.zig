const std = @import("std");
const termy = @import("termy");

// This is a test
pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    // Create a buffered writer
    const stdout = std.Io.File.stdout();
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);
    termy.enableOutVT(stdout);

    
    try termy.cursor.moveRight(&writer, 20);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);
    try termy.cursor.moveLeft(&writer, 90);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);
}
