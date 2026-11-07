const std = @import("std");
const termy = @import("termy");

// This file just has some abitrary test!
pub fn main(init: std.process.Init) !void {
    const stdin = std.Io.File.stdin();
    const stdout = std.Io.File.stdout();
    var buffer: [1024]u8 = undefined;

    var tty: termy.Tty = .init(init.io, stdout, &buffer, stdin);
    var terminal: termy.Terminal = .init(&tty);
    var input: termy.Input = .init(&tty);
    var writer = tty.writer();
    var x: std.ArrayList(termy.event.Event) = .empty;

    defer {
        for (x.items) |i| {
            var w: std.Io.Writer.Allocating = .init(std.heap.smp_allocator);
            defer w.deinit();
            std.json.Stringify.value(i, .{ .whitespace = .indent_2 }, &w.writer) catch {};
            std.debug.print("{s}\n", .{w.written()});
        }
    }

    defer writer.flush() catch {};
    try terminal.enableCp();
    defer terminal.restoreCp() catch {};

    const En = termy.Terminal.Enhancements;
    try terminal.enableEnhancements(En.DISAMBIGUATE_ESCAPE_CODES | En.REPORT_EVENT_TYPES | En.REPORT_ALL_KEYS_AS_ESCAPE_CODES);
    defer terminal.disableEnhancements() catch {};

    try terminal.enableMouseCapture();
    defer terminal.disablesMouseCapture() catch {};

    try terminal.enableFocusChange();
    defer terminal.disablesFocusChange() catch {};

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};
    try writer.flush();

    while (true) {
        if (try input.poll(.fromMilliseconds(20))) {
            const event = try input.read();
            try x.append(std.heap.smp_allocator, event);
            switch (event) {
                .key => |key| {
                    switch (key.code) {
                        .Char => |ch| {
                            if (ch == 'q') break;
                        },
                        else => {},
                    }
                },
                .resize => |r| {
                    std.debug.print("Hello Resize!, r: {}, c: {}\n", .{ r[0], r[1] });
                },
                .mouse => |mouse| {
                    switch (mouse.kind) {
                        .Down => std.debug.print("Down", .{}),
                        .Up => std.debug.print("Up", .{}),
                        .Moved => std.debug.print("Moved", .{}),
                        .Drag => std.debug.print("Drag", .{}),
                        .ScrollUp => std.debug.print("ScrollUp", .{}),
                        .ScrollDown => std.debug.print("ScrollDown", .{}),
                        .ScrollLeft => std.debug.print("ScrollLeft", .{}),
                        .ScrollRight => std.debug.print("ScrollRight", .{}),
                    }
                },
                .FocusGained => std.debug.print("FocusGained", .{}),
                .FocusLost => std.debug.print("FocusLost", .{}),
            }
        }
    }
}
