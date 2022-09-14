const std = @import("std");

test {
    const Test = struct {
        x: u64,
        y: u128
    };
    var t = Test {
        .x = 1,
        .y = 1
    };
    t.y += 1;
    std.debug.print("{}\n", .{t.y}); 
}