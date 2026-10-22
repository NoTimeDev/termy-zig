## What is termy?
**termy** is a terminal maniuplation library written in Zig, inspired by the Rust library [crossterm](https://github.com/crossterm-rs/crossterm).  

termy aims to provide a simple API for interacting with Windows and Unix terminals.  
This library is still in early development.

**Terminal maniuplation?** termy is not a tui framework, it does not provide widgets, it does not auto enter raw mode or alternate screen, it does not choose the input or output files, it is meant to be a low level library for interacting with terminals


Simple example below 
```zig 
const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    var buffer: [1024]u8 = undefined;
    // Create a buffered writer 
    var writer: std.Io.File.Writer = .init(std.Io.File.stdout(), init.io, &buffer);

    // execute automatically flushes 
    try termy.execute(&writer, .{
        termy.style.Color{.Red = {}},
        termy.style.Print{.msg = "Some Error!\n"},
        termy.style.Color{.Reset = {}},
    });
}
```
