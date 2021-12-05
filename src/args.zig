const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const expect = testing.expect;

/// An interface for std.process.args which works like C's argc/argv. It just
/// builds upfront an slice containing all of the arguments so that they can be
/// accessed directly.
pub const Args = struct {
    argv: [][]u8,
    argc: usize,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !Args {
        var it = std.process.args();
        var n: usize = 0;

        while (it.skip()) {
            n += 1;
        }

        var args = try allocator.alloc([]u8, n);

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

    pub fn has(self: Args, arg: []const u8) bool {
        for (self.argv) |current| {
            if (std.mem.eql(u8, current, arg)) {
                return true;
            }
        }

        return false;
    }

    pub fn countNonFlagArgs(self: Args) u8 {
        var c: usize = 0;
        for (self.argv) |arg| {
            if (arg[0] != '-') {
                c += 1;
            }
        }

        return c;
    }

    pub const ArgsIteratorMode = enum {
        Flags,
        NonFlags,
        All,
    };

    pub const ArgsIterator = struct {
        args: *const Args,
        cur: usize = 0,
        mode: ArgsIteratorMode = .All,

        pub fn init(args: *const Args, mode: ArgsIteratorMode) ArgsIterator {
            return .{
                .cur = 0,
                .args = args,
                .mode = mode,
            };
        }

        pub fn next(self: *ArgsIterator) ?[]const u8 {
            while (true) {
                if (self.cur >= self.args.argc) {
                    return null;
                }

                var ok: bool = switch (self.mode) {
                    .Flags => self.args.argv[self.cur][0] == '-',
                    .NonFlags => self.args.argv[self.cur][0] != '-',
                    .All => true,
                };

                if (ok) {
                    defer self.cur += 1;
                    return self.args.argv[self.cur];
                }

                self.cur += 1;
            }
        }
    };

    pub fn nonFlagArgsIterator(self: Args) ArgsIterator {
        return ArgsIterator.init(&self, .NonFlags);
    }

    pub fn flagArgsIterator(self: Args) ArgsIterator {
        return ArgsIterator.init(&self, .Flags);
    }
    pub fn argsIterator(self: Args) ArgsIterator {
        return ArgsIterator.init(&self, .All);
    }
};

pub fn addArg(self: *Args, arg: []const u8) !void {
    var argCopy = try self.allocator.alloc(u8, arg.len);
    @memcpy(argCopy.ptr, arg.ptr, arg.len);

    var newArgv = try self.allocator.alloc([]u8, self.argc + 1);
    @memcpy(std.mem.sliceAsBytes(newArgv).ptr, std.mem.sliceAsBytes(self.argv).ptr, self.argc * @sizeOf([]u8));
    self.allocator.free(self.argv);
    self.argv = newArgv;

    self.argv[self.argc] = argCopy;
    self.argc += 1;
}

test "Args" {
    var args = try Args.init(std.testing.allocator);
    defer args.deinit();

    try expect(args.argc == 2);

    try addArg(&args, "test");
    try expect(args.argc == 3);

    var end: usize = args.argv[1].len;
    var start = end - 3;
    try expect(std.mem.eql(u8, args.argv[1][start..end], "zig"));

    try expect(std.mem.eql(u8, args.argv[2], "test"));
    try expect(args.has("test"));
}
