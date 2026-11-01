const std = @import("std");
const termy = @import("termy");

const Field = struct {
    prompt: []const u8,
    placeholder: []const u8,
    value: std.ArrayList(u8) = .empty,
};

pub fn main(init: std.process.Init) !void {
    const stdin = try termy.sysIn(init.io);
    const stdout = try termy.sysOut(init.io);

    var output_state: termy.OutputState = .init(stdout);
    var input_state: termy.InputState = .init(stdin);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);
    var terminal: termy.Terminal = .init(
        &output_state,
        &input_state,
        &writer,
        stdin.handle,
    );

    var input: termy.Input = .init(
        &input_state,
        init.io,
        stdin,
    );

    var cursor: termy.Cusor = .init(&output_state, &writer);
    var style: termy.Style = .init(&output_state, &writer);

    defer writer.flush() catch {};

    const cpi = try termy.enableCp();
    defer termy.restoreCp(cpi) catch {};

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};

    try writer.interface.writeAll("Termy Project Generator\n");
    try writer.interface.writeAll("Esc to exit\n");
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
        if (try input.poll(.fromMilliseconds(20))) {
            const event = try input.read();

            switch (event) {
                .key => |key| switch (key.code) {
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

                        try writer.interface.print(
                            "{s}: ",
                            .{current.prompt},
                        );
                        try writer.interface.writeAll(current.value.items);

                        if (current_field + 1 == fields.len) {
                            break;
                        }

                        current_field += 1;
                        try writer.interface.writeAll("\n");
                    },

                    .Char => |ch| {
                        const current = &fields[current_field];

                        try current.value.append(
                            std.heap.smp_allocator,
                            @intCast(ch),
                        );
                    },

                    else => {},
                },
            }
        }

        const current = &fields[current_field];

        try cursor.moveToColumn(0);
        try terminal.clear(.CurrentRow);

        try writer.interface.print("{s}: ", .{current.prompt});

        if (current.value.items.len == 0) {
            try style.setAttribute(.Dim);
            try writer.interface.writeAll(current.placeholder);
            try style.setAttribute(.NormalIntensity);

            try cursor.moveToColumn(
                @intCast(current.prompt.len + 3),
            );
        } else {
            try writer.interface.writeAll(current.value.items);
        }

        try writer.flush();
    }

    if (cancelled) {
        try writer.interface.writeAll("\nUser Cancelled!\n");
    } else {
        try writer.interface.writeAll("\n\nProject settings:\n");

        for (fields) |field| {
            try writer.interface.print(
                "    {s}: {s}\n",
                .{ field.prompt, field.value.items },
            );
        }
    }
}
