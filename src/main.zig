const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const expect = testing.expect;

/// An interface for std.process.args which works like C's argc/argv. It just
/// builds upfront an slice containing all of the arguments so that they can be
/// accessed directly.
const Args = struct {
    argv: [][:0]u8,
    argc: usize,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) !Args {
        var it = std.process.args();
        var n: usize = 0;

        while (it.skip()) {
            n += 1;
        }

        var args = try allocator.alloc([:0]u8, n);

        it = std.process.args();

        var i: usize = 0;
        while (it.next(allocator)) |arg| {
            args[i] = try arg;
            i += 1;
        }

        return Args{
            .argv = args,
            .argc = n,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Args) void {
        for (self.argv) |arg| {
            self.allocator.free(arg);
        }

        self.allocator.free(self.argv);
    }
};

test "Args" {
    var args = try Args.init(std.testing.allocator);
    defer args.deinit();

    try expect(args.argc == 2);

    var end: usize = args.argv[1].len;
    var start = end - 3;
    try expect(std.mem.eql(u8, args.argv[1][start..end], "zig"));
}
