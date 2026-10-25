const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    const stdout = std.Io.File.stdout();

    var out: termy.OutputTty = .init(init.io, stdout, &buffer);
   
    try out.setCursorStyle(.SteadyBlock);
    try out.writer().flush();
    try std.Io.sleep(init.io, .fromSeconds(2), .awake);
    try out.setCursorStyle(.DefaultUserShape);
    try out.writer().flush();
}
