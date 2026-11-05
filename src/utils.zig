const std = @import("std");

pub fn Lazy(comptime T: type, comptime init_fn: anytype) type{
    return struct {
        val: ?T = null,
        pub fn get(self: *@This(), args: anytype) T{
            if(self.val)|v| return v;
            const v = @call(.auto, init_fn, args);
            self.val = v;
            return v;
        }
    };
}

pub fn Ring(comptime T: type, comptime capacity: usize) type{
    return struct {
        items: [capacity]T = undefined,
        head: usize = 0,
        tail: usize = 0,
        len: usize = 0,

        pub fn push(self: *@This(), item: T) void{
            self.items[self.tail] = item;
            self.tail = (self.tail + 1) % capacity;
            if(self.len == capacity){
                self.head = (self.head + 1) % capacity;
            }else{
                self.len+=1;
            }
        }


        pub fn pop(self: *@This()) ?T{
            if(self.len == 0) return null;

            const v = self.items[self.head];
            self.head = (self.head + 1) % capacity;
            self.len-=1;
            return v;
        }

        pub fn size(self: *@This()) usize{
            return self.len;
        }
    };
}
