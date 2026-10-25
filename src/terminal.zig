const Platform = @import("platform.zig").Platform;
const std = @import("std");
const builtin = @import("builtin");

/// Provides functions to change how the terminal behaves
pub const Terminal = struct {
    platform: *Platform,
    writer: *std.Io.File.Writer,

    /// Enter an alternate screen
    pub fn enterAlternateScreen(self: *Terminal) !void{
        _ = self;
    }

    /// Enter an alternate screen
    pub fn leaveAlternateScreen(self: *Terminal) !void{
        _ = self;

    }
};
