const std = @import("std");
const TIME_BITS = 48;
const RAND_BITS = 80;
const ULID_BIT_LEN = 128;
const rand = std.crypto.random;
const MAX_RAND: u128 = (1 << 80) - 1;
const BASE = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const ENCODED_LEN = 26;

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

    pub fn source(self: *Self) UlidError!u128{
        const timestamp = @intCast(u64, std.time.milliTimestamp());
        if (self.time != undefined) {
            if (self.time == timestamp) {
                if (self.rand != MAX_RAND) {
                    self.rand += 1;
                    return self.gen_bit();
                } else {
                    return UlidError.MaxRand;
                }
            } else {
                self.time = @as(u64, timestamp);
                self.gen_rand();
                return self.gen_bit();
            }
        } else {
            self.time = timestamp;
            self.gen_rand();
            return self.gen_bit();
        }
    }

    fn gen_rand(self: *Self) void {
        self.rand = rand.int(u80);
    }

    fn gen_bit(self: Self) u128 {
        return @as(u128, self.time) << 80 | self.rand;
    }

    fn ulid_bit(self: Self) [ULID_BIT_LEN:0]u8 {
        var src = try self.ulid_source();
        return to_binary(src);
    }
};

fn to_binary(src: u128) [ULID_BIT_LEN:0]u8 {
    var v = src;
    var result: [ULID_BIT_LEN:0]u8 = undefined;
    var i: u8 = 0;
    while (i < ULID_BIT_LEN) {
        const bit = @intCast(u1, v & 1);
        result[ULID_BIT_LEN - i - 1] = if (bit == 1) '1' else '0';
        v = v >> 1;
        i += 1;
   }
   return result;
}

fn encode_base32(src: u128) [ENCODED_LEN:0]u8 {
    var buffer: [ENCODED_LEN:0]u8 = undefined;
    var source = src;
    var i: u5 = 0;
    while (i < ENCODED_LEN) {
        const index: u5 = @intCast(u5, source & 0x1f);
        buffer[ENCODED_LEN - i - 1] = BASE[index];
        source = source >> 5;
        i += 1;
    }
    return buffer;
}

test {
    var generator = Ulid.new();
    const ulid1 = try generator.source();
    const ulid2 = try generator.source();
    std.debug.print("{}\n", .{ulid1});
    const bin = to_binary(ulid1);
    const encoded1 = encode_base32(ulid1);
    const encoded2 = encode_base32(ulid2);

    std.debug.print("{s}\n", .{bin});
    std.debug.print("{s}\n", .{encoded1});
    std.debug.print("{s}\n", .{encoded2});
}
