const std = @import("std");

pub fn filenameWithoutExtension(name: []const u8) []const u8 {
    var i: usize = name.len;

    while (i > 0) {
        if (name[i - 1] == '.') {
            return name[0..(i - 1)];
        }

        i -= 1;
    }

    return name;
}

fn rangeArray(comptime T: type, start: comptime_int, end: comptime_int) [end - start]T {
    var result = [_]T{0} ** (end - start);

    var i = @intCast(usize, start);
    inline while (i < end) : (i += 1) {
        result[i - start] = i;
    }

    return result;
}

// Tests
const expect = std.testing.expect;

test "filenameWithoutExtension" {
    var result = filenameWithoutExtension("file.ext");

    try expect(std.mem.eql(u8, result, "file"));
}

test "rangeArray" {
    // TODO: add tests...
}
