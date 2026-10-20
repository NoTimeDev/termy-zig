const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("termy", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "termy",
        .root_module = mod,
    });

    b.installArtifact(lib);

    const run_step = b.step("test", "Build and run all test programs");
    for([_][]const u8{
        "tests/tests.zig"
    }) |path|{
        const exe = b.addExecutable(.{
            .name = std.fs.path.stem(path),
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{.name = "termy", .module = mod}
                }
            })
        });
        const run = b.addRunArtifact(exe);
        run_step.dependOn(&run.step);
    }
}
