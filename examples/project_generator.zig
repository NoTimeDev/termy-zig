//! A simple interactive cli 

const std = @import("std");
const termy = @import("termy");

/// Represents a Field
const Field = struct {
    /// Promt, text displayed before output
    prompt: []const u8,
    
    /// Dimmed text when a field is empty
    placeholder: []const u8,

    /// User-provided input, this is leaked because im lazy
    value: std.ArrayList(u8) = .empty,
};

pub fn main(init: std.process.Init) !void {
    const stdin = std.Io.File.stdin();
    const stdout = std.Io.File.stdout();

    var buffer: [1024]u8 = undefined;
    
    // Init our tools
    var tty: termy.Tty = .init(init.io, stdout, &buffer, stdin);
    var terminal: termy.Terminal = .init(&tty);
    var input: termy.Input = .init(&tty);
    var cursor: termy.Cursor = .init(&tty);
    var style: termy.Style = .init(&tty);
    var writer = tty.writer();

    // Flushing is not garuanteed, this flushes everything to the screen at the end of the program
    defer writer.flush() catch {};

    // This is not necessary, But it dosent hurt! 
    try terminal.enableEnhancements(termy.Terminal.Enhancements.REPORT_ALL_KEYS_AS_ESCAPE_CODES | termy.Terminal.Enhancements.REPORT_EVENT_TYPES | termy.Terminal.Enhancements.REPORT_ALTERNATE_KEYS | termy.Terminal.Enhancements.DISAMBIGUATE_ESCAPE_CODES);
    defer terminal.disableEnhancements() catch {};

    // Set the codepage to utf8 
    try terminal.enableCp();
    defer terminal.restoreCp() catch {};

    // Enables raw mode 
    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};

    // Write the greeting to the screen 
    try writer.writeAll("Termy Project Generator\n");
    try writer.writeAll("Esc to exit\n");
    try writer.flush();

    // Our list or fields
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
                .Key => |key| {
                    // Ensure its not a release kind
                    if (key.kind != .Press) continue;

                    switch (key.code) {
                        .Esc => {
                            // User cancelled the program
                            cancelled = true;
                            break;
                        },

                        .Backspace => {
                            // if a char is available remove it
                            const current = &fields[current_field];
                            if (current.value.items.len != 0) {
                                _ = current.value.pop();
                            }
                        },

                        .Enter => {
                            // The user has submited the info
                            const current = &fields[current_field];

                            try cursor.moveToColumn(0);
                            // Clear the row 
                            try terminal.clear(.CurrentRow);

                            // Print the current field 
                            try writer.print(
                                "{s}: ",
                                .{current.prompt},
                            );

                            // Write the users response 
                            try writer.writeAll(current.value.items);

                            if (current_field + 1 == fields.len) {
                                // No more fields!
                                break;
                            }

                            // Move on to the next field
                            current_field += 1;
                            try writer.writeAll("\n");
                        },

                        .Char => |ch| {
                            // Add the current char to the arraylist
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

        // Clear the current row 
        try cursor.moveToColumn(0);
        try terminal.clear(.CurrentRow);

        // Write the prompt
        try writer.print("{s}: ", .{current.prompt});

        if (current.value.items.len == 0) {
            // If there is nothing write the placeholder

            // Note: Yes dim could be used here, but BrightBlack looks better :P 
            try style.setForegroundColor(.BrightBlack);
            try writer.writeAll(current.placeholder);
            try style.setForegroundColor(.Reset);

            // Move the cursor to a the start of the placeholder
            try cursor.moveToColumn(
                @intCast(current.prompt.len + 3),
            );
        } else {
            // Write the users current response
            try writer.writeAll(current.value.items);
        }

        // Write everything to the screen
        try writer.flush();
    }

    if (cancelled) {
        try writer.writeAll("\nUser Cancelled!\n");
    } else {
        try writer.writeAll("\n\nProject settings:\n");

        // Write the prompt and the responses
        for (fields) |field| {
            try writer.print(
                "    {s}: {s}\n",
                .{ field.prompt, field.value.items },
            );
        }
    }
}
