# What is termy?
**termy** is a cross-platform terminal maniuplation library written in Zig, inspired by the Rust library [crossterm](https://github.com/crossterm-rs/crossterm).  

It provides a simple, allocation free API for interacting with terminals on Windows and Unix-like systems.

view the [docs](https://notimedev.github.io/termy-zig), and the [examples](https://github.com/NoTimeDev/termy-zig/tree/main/examples) to get a feel for the library.

Simple termy examples
```zig
// Using colour.
const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    const stdout = std.Io.File.stdout();

    var buffer: [1024]u8 = undefined;

    var tty: termy.Tty = .init(init.io, stdout, &buffer, null);
    const writer = tty.writer();
    
    var style: termy.Style = .init(&tty);
    

    try style.setForegroundColor(.BrightCyan);
    try writer.writeAll("Welcome To Termy!\n");
    try style.setForegroundColor(.Reset);

    try writer.flush();
}
```

```zig
// A simple input example
const termy = @import("termy");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const out = try termy.sysOut();
    const in = try termy.sysIn();
    
    var buffer: [1024]u8 = undefined;
    
    var tty: termy.Tty = .init(init.io, out, &buffer, in);
    const writer = tty.writer();

    var input: termy.Input = .init(&tty);
    var terminal: termy.Terminal = .init(&tty);
    
   
    // Enter an alternate screen
    try terminal.enterAlternateScreen();
    
    // Enable raw mode 
    try terminal.enableRawMode();

    // termy does not flush when writing commands, we must flush  
    try writer.flush();

    while(true){
        if(try input.poll(.fromMilliseconds(20))){
            switch (try input.read()) {
                .Key => |key|{
                    switch (key.code) {

                        .Char => |ch|{
                        
                            // exit if the user clicked q
                            if(ch == 'q'){
                                break;
                            }
                        },

                        else => {},
                    }
                },
                else => {},
            }

        }

    }


    // Disable raw mode 
    try terminal.disableRawMode();

    // leaves the alternate screen 
    try terminal.leaveAlternateScreen();

    // a little text
    try writer.writeAll("Program Ended!\n");
    try writer.flush();
}
```
