const std = @import("std");

const sys = std.os.system;

const tcgetattr = std.os.tcgetattr;
const tcsetattr = std.os.tcsetattr;
const stdin = std.os.STDERR_FILENO;
const stdout = std.os.STDOUT_FILENO;
const echo = sys.ECHO;
const icanon = sys.ICANON;

var originalTermios: ?std.os.termios = null;

pub fn enableRawMode() anyerror!void {
    originalTermios = try tcgetattr(stdin);
    var raw = originalTermios.?;
    raw.lflag &= ~(@intCast(sys.tcflag_t, echo) | @intCast(sys.tcflag_t, icanon));
    try tcsetattr(stdin, sys.TCSA.FLUSH, raw);
}

pub fn disableRawMode() anyerror!void {
    if (originalTermios) |termios| {
        try tcsetattr(stdin, sys.TCSA.FLUSH, termios);
        originalTermios = null;
    }
}

pub fn disableRawModeUnsafe() void {
    if (originalTermios) |termios| {
        tcsetattr(stdin, sys.TCSA.FLUSH, termios) catch unreachable;
        originalTermios = null;
    }
}

pub const TermKeyEventType = enum {
    Char,
    Esc,
    Enter,
    Left,
    Right,
    Up,
    Down,
    Other,
};

pub const TermKeyEvent = struct {
    type: TermKeyEventType,
    char: u8 = undefined,
};

pub fn readKey() !?TermKeyEvent {
    var buf: [3]u8 = undefined;
    var result: ?TermKeyEvent = null;

    var n = try std.os.read(stdin, &buf);

    if (n == 0) {
        result = null;
    } else if (n == 1) {
        var char = buf[0];

        result = switch (char) {
            27 => TermKeyEvent{ .type = .Esc },
            10 => TermKeyEvent{ .type = .Enter },
            else => TermKeyEvent{ .type = .Char, .char = char },
        };
    } else if (n == 3) {
        if (buf[0] == 27 and buf[1] == 91) {
            return switch (buf[2]) {
                65 => TermKeyEvent{ .type = .Up },
                66 => TermKeyEvent{ .type = .Down },
                67 => TermKeyEvent{ .type = .Right },
                68 => TermKeyEvent{ .type = .Left },
                else => TermKeyEvent{ .type = .Other },
            };
        }
    } else {
        result = TermKeyEvent{ .type = .Other };
    }

    return result;
}
// On windows:
// [using <termio.h> in windows](https://comp.programming.narkive.com/F6D2mhYF/using-termio-h-in-windows) ([archive](https://web.archive.org/web/20211204001943/https://comp.programming.narkive.com/F6D2mhYF/using-termio-h-in-windows))
// Old-ass forum post
// pub fn main() !void {
//     // var buf: [3]u8 = undefined;

//     try enableRawMode();
//     defer disableRawModeUnsafe();

//     _ = num(12);

//     while (try readKey()) |key| {
//         switch (key.type) {
//             .Char => {
//                 _ = try std.os.write(stdout, &[_]u8{key.char});
//             },
//             .Enter => {
//                 _ = try std.os.write(stdout, &[_]u8{'\n'});
//             },
//             .Esc => {
//                 break;
//             },
//             else => {},
//         }
//     }

// var n: usize = 0;
// while (true) {
//     n = try std.os.read(stdin, &buf);

//     if (n == 0) break;

//     if (n == 1) {
//         if (buf[0] == 27) {
//             break;
//         }

//         // if (buf[0] == 10) {
//         // try disableRawMode();
//         // std.log.info("newline!", .{});
//         // }

//         _ = try std.os.write(stdout, buf[0..1]);
//     }

//     if (n == 3) {
//         std.log.info("{any}", .{buf[0..n]});
//     }
// }

// try disableRawMode();
// }
