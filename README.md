# What is termy?
**termy** is a cross-platform terminal maniuplation library written in Zig, inspired by the Rust library [crossterm](https://github.com/crossterm-rs/crossterm).  

It provides a simple, allocation free API for interacting with terminals on Windows and Unix-like systems.

view the [docs](https://notimedev.github.io/termy-zig), and the [examples](https://github.com/NoTimeDev/termy-zig/tree/main/examples) to get a feel for the library.
termy is still in early development.

```zig
const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    const stdout = std.Io.File.stdout();

    var buffer: [1024]u8 = undefined;

    var tty: termy.Tty = .init(init.io, stdout, &buffer, null);
    var style: termy.Style = .init(&tty);
    
    const writer = tty.writer();

    try style.setForegroundColor(.BrightCyan);
    try writer.writeAll("Welcome To Termy!\n");
    try style.setForegroundColor(.Reset);

    try writer.flush();
}
```

## Future 

This is the future branch of termy-zig.  

This branch is unstable and subject to change at any time.

Changes made in this branch will eventually be merged into main once the goals have been completed and are considered stable.

### Goals
- [ ] **Documentation Changes** - Rework and improve the documentation.  
- [ ] **Optional Features** - Add optional functionality through build flags.  
