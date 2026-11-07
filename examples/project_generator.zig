const std = @import("std");
const termy = @import("termy");

const Field = struct {
    prompt: []const u8,
    placeholder: []const u8,
    value: std.ArrayList(u8) = .empty,
};

pub fn main(init: std.process.Init) !void {
    const stdin = try termy.sysIn();
    const stdout = try termy.sysOut();

    var buffer: [1024]u8 = undefined;
    var tty: termy.Tty = .init(init.io, stdout, &buffer, stdin);
    var terminal: termy.Terminal = .init(&tty);
    var input: termy.Input = .init(&tty);
    var cursor: termy.Cusor = .init(&tty);
    var style: termy.Style = .init(&tty);
    var writer = tty.writer();

    defer writer.flush() catch {};

    try terminal.enableEnhancements(termy.Terminal.Enhancements.REPORT_ALL_KEYS_AS_ESCAPE_CODES | termy.Terminal.Enhancements.REPORT_EVENT_TYPES | termy.Terminal.Enhancements.REPORT_ALTERNATE_KEYS | termy.Terminal.Enhancements.DISAMBIGUATE_ESCAPE_CODES);
    defer terminal.disableEnhancements() catch {};

    try terminal.enableCp();
    defer terminal.restoreCp() catch {};

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};

    try writer.writeAll("Termy Project Generator\n");
    try writer.writeAll("Esc to exit\n");
    try writer.flush();

    var fields = [_]Field{
        .{
            .prompt = "Project Name",
            .placeholder = "e.g Termy-zig",
        },
        .{
            .prompt = "Author's Name",
            .placeholder = "e.g NoTimeDev",
        },
        .{
            .prompt = "Project's Description",
            .placeholder = "e.g A terminal manipulation library",
        },
    };

    var current_field: usize = 0;
    var cancelled = false;

    while (true) {
        if (try input.poll(.fromMilliseconds(500))) {
            const event = try input.read();

            switch (event) {
                .key => |key|{ 
                    if(key.kind != .Press) continue;
                    switch (key.code) {
                        .Esc => {
                            cancelled = true;
                            break;
                        },

                        .Backspace => {
                            const current = &fields[current_field];

                            if (current.value.items.len != 0) {
                                _ = current.value.pop();
                            }
                        },

                        .Enter => {
                            const current = &fields[current_field];

                            try cursor.moveToColumn(0);
                            try terminal.clear(.CurrentRow);

                            try writer.print(
                                "{s}: ",
                                .{current.prompt},
                            );
                            try writer.writeAll(current.value.items);

                            if (current_field + 1 == fields.len) {
                                break;
                            }

                            current_field += 1;
                            try writer.writeAll("\n");
                        },

                        .Char => |ch| {
                            const current = &fields[current_field];

                            try current.value.append(
                                std.heap.smp_allocator,
                                @intCast(ch),
                            );
                        },

                        else => {},
                    }
                },
                else => {},
            }
        }

        const current = &fields[current_field];

        try cursor.moveToColumn(0);
        try terminal.clear(.CurrentRow);

        try writer.print("{s}: ", .{current.prompt});

        if (current.value.items.len == 0) {
            try style.setForegroundColor(.BrightBlack);
            try writer.writeAll(current.placeholder);
            try style.setForegroundColor(.Reset);

            try cursor.moveToColumn(
                @intCast(current.prompt.len + 3),
            );
        } else {
            try writer.writeAll(current.value.items);
        }

        try writer.flush();
    }

    if (cancelled) {
        try writer.writeAll("\nUser Cancelled!\n");
    } else {
        try writer.writeAll("\n\nProject settings:\n");

        for (fields) |field| {
            try writer.print(
                "    {s}: {s}\n",
                .{ field.prompt, field.value.items },
            );
        }
    }
}
