const std = @import("std");
const TIME_BITS = 48;
const RAND_BITS = 80;
const ULID_BIT_LEN = 128;
const rand = std.crypto.random;
const MAX_RAND: u128 = (1 << 80) - 1;
const BASE = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const ENCODED_LEN = 26;

pub const UlidError = error {
    MaxRand,
};

pub const Ulid = struct {
    time: ?u64,
    rand: ?u128,

    const Self = @This();

    pub fn new() Ulid {
        return Ulid {
            .time = null,
            .rand = null
        };
    }

    pub fn source(self: *Self) UlidError!u128{
        const timestamp = @intCast(u64, std.time.milliTimestamp());
        if (self.time != null) {
            if (self.time == timestamp) {
                if (self.rand != MAX_RAND) {
                    self.rand.? += 1;
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
        return @as(u128, self.time.?) << 80 | self.rand.?;
    }

    fn ulid_bit(self: Self) [ULID_BIT_LEN:0]u8 {
        var src = try self.ulid_source();
        return to_binary(src);
    }
};

pub fn to_binary(src: u128) [ULID_BIT_LEN:0]u8 {
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

pub fn encode_base32(src: u128) [ENCODED_LEN:0]u8 {
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
    // example: 2010743602507803096168807030878758460
    std.debug.print("{}\n", .{ulid1});
    const bin = to_binary(ulid1);
    const encoded1 = encode_base32(ulid1);
    const encoded2 = encode_base32(ulid2);

    // example: 00000001100000110100000101010000010010111000100101111100011101001110110010011001000010010101110011100111011111011110011000111100
    std.debug.print("{s}\n", .{bin});
    // Should generate monotonic ulids.
    // example: 01GD0N0JW9FHTES689BKKQVSHW
    //          01GD0N0JW9FHTES689BKKQVSHX
    std.debug.print("{s}\n", .{encoded1});
    std.debug.print("{s}\n", .{encoded2});

    const example = 2010743602507803096168807030878758460;
    const example_bin = to_binary(example);
    const example_encoded = encode_base32(example);

    try std.testing.expectEqualSlices(u8, &example_bin, "00000001100000110100000101010000010010111000100101111100011101001110110010011001000010010101110011100111011111011110011000111100");
    try std.testing.expectEqualSlices(u8, &example_encoded, "01GD0N0JW9FHTES689BKKQVSHW");
}
