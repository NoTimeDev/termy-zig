const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void {
    const stdout = try termy.sysout(init.io);
    var buffer: [1024]u8 = undefined;

    var platform: termy.Platform = .init(&stdout);
    var writer: std.Io.File.Writer = .init(stdout, init.io, &buffer);

    var style: termy.Style = .{
        .platform = &platform,
        .writer = &writer,
    };

    try writer.interface.writeAll("termy - Colors and styles\n\n");

    // Standard foreground colors
    try writer.interface.writeAll("Standard colors:\n");
    
    try style.setForegroundColor(.Red);
    try writer.interface.writeAll("Red ");

    try style.setForegroundColor(.Green);
    try writer.interface.writeAll("Green ");
    
    try style.setForegroundColor(.Blue);
    try writer.interface.writeAll("Blue ");
    
    try style.setForegroundColor(.Yellow);
    try writer.interface.writeAll("Yellow ");
    
    try style.setForegroundColor(.Magenta);
    try writer.interface.writeAll("Magenta ");
    
    try style.setForegroundColor(.Cyan);
    try writer.interface.writeAll("Cyan\n");

    try style.setForegroundColor(.Reset);
    try writer.interface.writeAll("\nBright colors:\n");

    // Bright foreground colors
    try style.setForegroundColor(.BrightRed);
    try writer.interface.writeAll("Bright red ");
    
    try style.setForegroundColor(.BrightGreen);
    try writer.interface.writeAll("Bright green ");
    
    try style.setForegroundColor(.BrightBlue);
    try writer.interface.writeAll("Bright blue ");
    
    try style.setForegroundColor(.BrightYellow);
    try writer.interface.writeAll("Bright yellow\n");

    try style.setForegroundColor(.Reset);
    
    try writer.interface.writeAll("\nBackground colors:\n");

    // Background colors
    try style.setBackgroundColor(.Red);
    try writer.interface.writeAll(" Red ");
    
    try style.setBackgroundColor(.Green);
    try writer.interface.writeAll(" Green ");
    
    try style.setBackgroundColor(.Blue);
    try writer.interface.writeAll(" Blue ");
    
    try style.setBackgroundColor(.Reset);
    try writer.interface.writeAll("\n\n");

    // RGB foreground colors
    try writer.interface.writeAll("RGB colors: ");
    
    try style.setForegroundColor(.{
        .Rgb = .{ .r = 255, .g = 128, .b = 0 },
    });
    
    try writer.interface.writeAll("Orange ");
    
    try style.setForegroundColor(.{
        .Rgb = .{ .r = 180, .g = 80, .b = 255 },
    });
    try writer.interface.writeAll("Purple");
    try style.setForegroundColor(.Reset);
    try writer.interface.writeAll("\n\n");

    // Text attributes
    try writer.interface.writeAll("Attributes:\n");

    try style.setAttribute(.Bold);
    try writer.interface.writeAll("Bold\n");
    try style.setAttribute(.NormalIntensity);

    try style.setAttribute(.Dim);
    try writer.interface.writeAll("Dim\n");
    try style.setAttribute(.NormalIntensity);

    try style.setAttribute(.Italic);
    try writer.interface.writeAll("Italic\n");
    try style.setAttribute(.NoItalic);

    try style.setAttribute(.Underlined);
    try writer.interface.writeAll("Underlined\n");
    try style.setAttribute(.NoUnderline);

    try style.setAttribute(.Reverse);
    try writer.interface.writeAll("Reverse\n");
    try style.setAttribute(.NoReverse);

    try style.setAttribute(.CrossedOut);
    try writer.interface.writeAll("Crossed out\n");
    try style.setAttribute(.NotCrossedOut);

    try writer.interface.writeAll("\n");

    // Underline color
    try writer.interface.writeAll("Underline color: ");
    try style.setUnderlineColor(.{
        .Rgb = .{ .r = 255, .g = 80, .b = 120 },
    });
    try style.setAttribute(.Underlined);
    try writer.interface.writeAll("Pink underline\n");
    try style.setAttribute(.NoUnderline);
    try style.setUnderlineColor(.Reset);

    // Restore default colors and flush buffered output
    try style.setForegroundColor(.Reset);
    try style.setBackgroundColor(.Reset);
    try writer.flush();
}
