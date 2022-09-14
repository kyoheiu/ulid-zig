const std = @import("std");
const TIME_BITS = 48;
const rndGen = std.rand.DefaultPrng;
const MAX_RAND: u128 = (1 << 80) - 1;

const UlidError = error {
    MaxRand,
};

const Ulid = struct {
    time: u64,
    rand: u128,

    const Self = @This();

    pub fn new() Ulid {
        return Ulid {
            .time = undefined,
            .rand = undefined
        };
    }

    pub fn ulid(self: *Self) UlidError!void {
        const timestamp = @intCast(u64, std.time.milliTimestamp());
        if (self.time != undefined) {
            if (self.time == timestamp) {
                if (self.rand != MAX_RAND) {
                    self.rand += 1;
                } else {
                    return UlidError.MaxRand;
                }
            } else {
                self.time = @as(u64, timestamp);
                self.gen_rand();
            }
        } else {
            self.time = timestamp;
            self.gen_rand();
        }
    }

    fn gen_rand(self: *Self) void {
        const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
        var rnd = rndGen.init(seed);
        const rand16 = rnd.random().int(u16);
        const rand64 = rnd.random().int(u64);
        self.rand = @as(u128, rand16) << 64 | rand64;
        std.debug.print("{b}\n", .{self.rand});
    }
};


pub fn main() !void {
    var gen = Ulid.new();
    try gen.ulid();
}
