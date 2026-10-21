const std = @import("std");
const termy = @import("termy");

pub fn main(init: std.process.Init) !void{
    //TODO: DOES NOT WORK ON WINDOWS... FUCK YOU MICROSOFT!
    var buffer: [1024]u8 = undefined;
    var term: termy.terminal.Terminal = try .init(init.io, &buffer);
   
    var events: std.ArrayList(termy.event.Event) = .empty;
    while (true) {
        if(try term.poll(.fromMilliseconds(20))){
            const event = try term.read();
            switch (event) {
                .Key => |K|{
                    switch (K.code) {
                        .Char => |ch|{
                            if(ch == 'q'){
                                break;
                            }
                        },
                        else => {}
                    }
                },
                else => {}
            }
            try events.append(std.heap.smp_allocator, event);
        }
    }
    term.deinit();
    for(events.items)|item|{
        std.debug.print("{}\n", .{item});
    }
}
