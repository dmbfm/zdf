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

const expect = std.testing.expect;

test "filenameWithoutExtension" {
    var result = filenameWithoutExtension("file.ext");

    try expect(std.mem.eql(u8, result, "file"));
}
