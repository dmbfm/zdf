const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("zdf", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    // var main_tests = b.addTest("src/main.zig");
    // main_tests.setBuildMode(mode);

    var args_tests = b.addTest("src/args.zig");
    args_tests.setBuildMode(.Debug);

    var utils_tests = b.addTest("src/utils.zig");
    utils_tests.setBuildMode(.Debug);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&args_tests.step);
    test_step.dependOn(&utils_tests.step);
}
