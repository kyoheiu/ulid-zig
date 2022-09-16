# ulid-zig

Simple [ULID](https://github.com/ulid/spec) implementation for zig.

This library started as a learning project, but IMO it can be used as it is.

## Usage
Just add `ulid.zig` as a package to your project. No external dependencies.

## Sample
See test block.

```zig
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
```
