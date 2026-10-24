const std = @import("std");
const termy = @import("termy");

// This is a test
pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    // Create a buffered writer
    const stdout = std.Io.File.stdout();
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);
    termy.enableOutVT(stdout);

    try termy.cursor.setCursorStyle(&writer, .SteadyBar);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);

    try termy.cursor.setCursorStyle(&writer, .BlinkingBar);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);

    try termy.cursor.setCursorStyle(&writer, .SteadyBlock);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);

    try termy.cursor.setCursorStyle(&writer, .BlinkingBlock);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);

    try termy.cursor.setCursorStyle(&writer, .SteadyUnderScore);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);
    
    try termy.cursor.setCursorStyle(&writer, .BlinkingUnderScore);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);

    try termy.cursor.setCursorStyle(&writer, .DefaultUserShape);
    try writer.flush();
    try std.Io.sleep(init.io, .fromSeconds(1), .awake);
}
