const std = @import("std");
const TIME_BITS = 48;
const ULID_BIT_LEN = 128;
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

    pub fn ulid(self: *Self) UlidError![]u1 {
        const timestamp = @intCast(u64, std.time.milliTimestamp());
        if (self.time != undefined) {
            if (self.time == timestamp) {
                if (self.rand != MAX_RAND) {
                    self.rand += 1;
                    return self.gen_ulid_bit();
                } else {
                    return UlidError.MaxRand;
                }
            } else {
                self.time = @as(u64, timestamp);
                self.gen_rand();
                return self.gen_ulid_bit();
            }
        } else {
            self.time = timestamp;
            self.gen_rand();
            return self.gen_ulid_bit();
        }
    }

    fn gen_rand(self: *Self) void {
        const seed = @truncate(u64, @bitCast(u128, std.time.nanoTimestamp()));
        var rnd = rndGen.init(seed);
        const rand16 = rnd.random().int(u16);
        const rand64 = rnd.random().int(u64);
        self.rand = @as(u128, rand16) << 64 | rand64;
    }

    fn gen_ulid_bit(self: Self) []u1 {
        const ulid_int: u128 = @as(u128, self.time) << 80 | self.rand;
        std.debug.print("{}\n", .{ulid_int});
        std.debug.print("{b}\n", .{ulid_int});
        return to_binary(ulid_int);
    }
};

fn to_binary(value: u128) []u1 {
    var v = value;
    var result: [ULID_BIT_LEN]u1 = undefined;
    var bit: u1 = 0;
    std.debug.print("\n", .{});
    var i: u8 = 0;
    while (i < ULID_BIT_LEN) {
        bit = @intCast(u1, v & 1); 
        std.debug.print("{}", .{bit});
        if (bit == 1) {
            result[ULID_BIT_LEN - i - 1] = 1;
        } else {
            result[ULID_BIT_LEN - i - 1] = 0;
        }
        v = v >> 1;
        i += 1;
   }
        std.debug.print("\n", .{});
   return &result;
}

pub fn main() !void {
    var gen = Ulid.new();
    const ulid = try gen.ulid();
    std.debug.print("{}\n", .{ulid.len});
    for (ulid) |c| {
        std.debug.print("{d}", .{c});
    }
}
