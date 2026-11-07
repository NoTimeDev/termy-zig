const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void {
    const stdout = std.Io.File.stdout();
    var buffer: [1024]u8 = undefined;
    var tty: termy.Tty = .init(init.io, stdout, &buffer, null);
    var style: termy.Style = .init(&tty);
    const writer = tty.writer();

    try writer.writeAll("termy - Colors and styles\n\n");

    // Standard foreground colors
    try writer.writeAll("Standard colors:\n");

    try style.setForegroundColor(.Red);
    try writer.writeAll("Red ");

    try style.setForegroundColor(.Green);
    try writer.writeAll("Green ");

    try style.setForegroundColor(.Blue);
    try writer.writeAll("Blue ");

    try style.setForegroundColor(.Yellow);
    try writer.writeAll("Yellow ");

    try style.setForegroundColor(.Magenta);
    try writer.writeAll("Magenta ");

    try style.setForegroundColor(.Cyan);
    try writer.writeAll("Cyan\n");

    try style.setForegroundColor(.Reset);
    try writer.writeAll("\nBright colors:\n");

    // Bright foreground colors
    try style.setForegroundColor(.BrightRed);
    try writer.writeAll("Bright red ");

    try style.setForegroundColor(.BrightGreen);
    try writer.writeAll("Bright green ");

    try style.setForegroundColor(.BrightBlue);
    try writer.writeAll("Bright blue ");

    try style.setForegroundColor(.BrightYellow);
    try writer.writeAll("Bright yellow\n");

    try style.setForegroundColor(.Reset);

    try writer.writeAll("\nBackground colors:\n");

    // Background colors
    try style.setBackgroundColor(.Red);
    try writer.writeAll(" Red ");

    try style.setBackgroundColor(.Green);
    try writer.writeAll(" Green ");

    try style.setBackgroundColor(.Blue);
    try writer.writeAll(" Blue ");

    try style.setBackgroundColor(.Reset);
    try writer.writeAll("\n\n");

    // RGB foreground colors
    try writer.writeAll("RGB colors: ");

    try style.setForegroundColor(.{
        .Rgb = .{ .r = 255, .g = 128, .b = 0 },
    });

    try writer.writeAll("Orange ");

    try style.setForegroundColor(.{
        .Rgb = .{ .r = 180, .g = 80, .b = 255 },
    });
    try writer.writeAll("Purple");
    try style.setForegroundColor(.Reset);
    try writer.writeAll("\n\n");

    // Text attributes
    try writer.writeAll("Attributes:\n");

    try style.setAttribute(.Bold);
    try writer.writeAll("Bold\n");
    try style.setAttribute(.NormalIntensity);

    try style.setAttribute(.Dim);
    try writer.writeAll("Dim\n");
    try style.setAttribute(.NormalIntensity);

    try style.setAttribute(.Italic);
    try writer.writeAll("Italic\n");
    try style.setAttribute(.NoItalic);

    try style.setAttribute(.Underlined);
    try writer.writeAll("Underlined\n");
    try style.setAttribute(.NoUnderline);

    try style.setAttribute(.Reverse);
    try writer.writeAll("Reverse\n");
    try style.setAttribute(.NoReverse);

    try style.setAttribute(.CrossedOut);
    try writer.writeAll("Crossed out\n");
    try style.setAttribute(.NotCrossedOut);

    try writer.writeAll("\n");

    // Underline color
    try writer.writeAll("Underline color: ");
    try style.setUnderlineColor(.{
        .Rgb = .{ .r = 255, .g = 80, .b = 120 },
    });
    try style.setAttribute(.Underlined);
    try writer.writeAll("Pink underline\n");
    try style.setAttribute(.NoUnderline);
    try style.setUnderlineColor(.Reset);

    // Restore default colors and flush buffered output
    try style.setForegroundColor(.Reset);
    try style.setBackgroundColor(.Reset);
    try writer.flush();
}
