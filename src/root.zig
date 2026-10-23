//! Root module for termy! 
//! Note: On windows if a handle does not support virtual terminal processing(VT) then windows ConsoleApi calls are made
//! this means no bytes will be writen to the writer

const builtin = @import("builtin");
const std = @import("std");
const sys = switch (builtin.os.tag) {
    .windows => @import("sys/windows/root.zig"),
    else => @import("sys/unix.zig")
};

// Note to self, make readme sound less ai-y

/// This returns the system's output file, this is different from stdout 
/// On windows this is "CONOUT$" on linux this is "/dev/tty"
pub const sysout = sys.sysout;

pub const cursor = @import("cursor.zig");
pub const style = @import("style.zig");

/// This function trys to enable VT output
/// On Unix systems, this function does nothing 
/// On Windows if this function cannot enable VT output
/// operations on this file will use ConsoleApi
pub const enableOutVT = sys.enableOutVT;
