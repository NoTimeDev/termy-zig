const std = @import("std");
const termy = @import("termy");

// This file just has some abitrary test!
pub fn main(init: std.process.Init) !void{
    const stdin = std.Io.File.stdin();
    const stdout = std.Io.File.stdout();

    var outstate: termy.OutputState = .init(stdout);
    var instate: termy.InputState = .init(stdin);
    var buffer: [1024]u8 = undefined;
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);

    var terminal: termy.Terminal = .init(&outstate, &instate, &writer, stdin.handle);
    var x: std.ArrayList(termy.event.Event) = .empty;
    
    defer {
        for(x.items)|i|{
            std.debug.print("{}\n", .{i});
        }
    }

    defer writer.flush() catch {};
    const cpi = try termy.enableCp();
    defer termy.restoreCp(cpi) catch {};

    const En = termy.Terminal.Enhancements;
    try terminal.enableEnhancements(En.DISAMBIGUATE_ESCAPE_CODES | En.REPORT_EVENT_TYPES | En.REPORT_ALL_KEYS_AS_ESCAPE_CODES);
    defer terminal.disableEnhancements() catch {};
    
    try terminal.enableFocusChange();
    defer terminal.disablesFocusChange() catch {};

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};
    try writer.flush();
    var input: termy.Input = .init(&instate, init.io, stdin);


    while (true) {
        if(try input.poll(.fromMilliseconds(20))){
            const event = try input.read();
            try x.append(std.heap.smp_allocator, event);
            switch (event) {
                .key => |key|{
                    switch (key.code) {
                        .Char => |ch|{
                            if(ch == 'q') break;
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }
    }
}
