pub const Args = @import("./args.zig").Args;
pub const utils = @import("./utils.zig");

const builtin = @import("builtin");

pub const Term = switch (builtin.os.tag) {
    .windows => @import("./term/windows.zig"),
    else => @import("./term/posix.zig"),
};
