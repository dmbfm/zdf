/// image.zig
///
/// Simple image type with 24bit RGB values. The pixel data is just a u8 array
/// where pixels are stored in (r, g, b) order. 
///
/// Has builtin .ppm output.
/// 
/// The fanciest part is the `shader` method that applies a "shader function"
/// to every pixel of the image.
const std = @import("std");
const Allocator = std.mem.Allocator;

data: []u8,
width: usize,
height: usize,
num_bytes: usize,
allocator: Allocator,

const Self = @This();

pub fn Rgb(comptime T: type) type {
    return struct {
        r: T,
        g: T,
        b: T,
    };
}

pub const Rgb8 = Rgb(u8);
pub const RgbFloat32 = Rgb(f32);
pub const RgbFloat64 = Rgb(f64);

pub fn ShaderFn(comptime T: type) type {
    return fn (T, T) Rgb(T);
}

pub fn Init(allocator: Allocator, w: usize, h: usize) !Self {
    var num_bytes = w * h * 3;
    return Self{
        .data = try allocator.alloc(u8, num_bytes),
        .width = w,
        .height = h,
        .num_bytes = num_bytes,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.data);
}

fn baseIndex(self: Self, x: usize, y: usize) void {
    return (y * self.width + x) * 3;
}

pub fn set(self: *Self, x: usize, y: usize, rgb: Rgb) void {
    var i = self.baseIndex(x, y);

    self.data[i] = rgb.r;
    self.data[i + 1] = rgb.g;
    self.data[i + 2] = rgb.b;
}

pub fn get(self: *Self, x: usize, y: usize) struct { r: u8, g: u8, b: u8 } {
    var i = self.baseIndex(x, y);

    return .{
        .r = self.data[i],
        .g = self.data[i + 1],
        .b = self.data[i + 2],
    };
}

pub fn fill(self: *Self, rgb: Rgb) void {
    var i: usize = 0;
    while (i < self.data.len) : (i += 3) {
        self.data[i] = rgb.r;
        self.data[i + 1] = rgb.g;
        self.data[i + 2] = rgb.b;
    }
}

pub fn ppm(self: Self, wr: anytype) !void {
    try wr.writeAll("P3\n");
    try wr.print("{} {}\n255\n", .{ self.width, self.height });

    var i: usize = 0;
    while (i < self.width * self.height * 3) : (i += 3) {
        var r = self.data[i];
        var g = self.data[i + 1];
        var b = self.data[i + 2];
        try wr.print("{} {} {}\n", .{ r, g, b });
    }
}

/// This will call the function `ps(u, v)` to every pixel of the image,
/// transforming the pixel's value according to the output of `ps`. The
/// arguments to `ps` are within the [0, 1] range, just like texture
/// coordinates.
///
/// `T` must be a float type, i.e., either `f32` or `f64`.
///
pub fn shader(self: *Self, comptime T: type, ps: ShaderFn(T)) void {
    if (@typeInfo(T) != .Float) {
        unreachable;
    }

    var dx: T = 1.0 / @intToFloat(T, self.width);
    var dy: T = 1.0 / @intToFloat(T, self.height);

    var i: usize = 0;
    while (i < self.data.len) : (i += 3) {
        var x = @rem(i / 3, self.width);
        var y = @divTrunc(i / 3, self.width);

        var u = @intToFloat(T, x) * dx;
        var v = @intToFloat(T, y) * dy;

        var c = ps(u, v);

        self.data[i] = @floatToInt(u8, std.math.clamp(c.r, 0, 1) * 255.0);
        self.data[i + 1] = @floatToInt(u8, std.math.clamp(c.g, 0, 1) * 255.0);
        self.data[i + 2] = @floatToInt(u8, std.math.clamp(c.b, 0, 1) * 255.0);
    }
}
