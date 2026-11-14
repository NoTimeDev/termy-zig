const std = @import("std");
pub const Backend = enum {
    fallback,
    vt,
    native,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const out = b.option(Backend, "out", "Output Backend: fallback, vt, native (default: fallback)") orelse .fallback;

    const options = b.addOptions();
    options.addOption(Backend, "out", out);

    const mod = b.addModule("termy", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addOptions("options", options);

    const lib = b.addLibrary(.{
        .name = "termy",
        .root_module = mod,
    });

    b.installArtifact(lib);

    const docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Generate HTML documentation");
    docs_step.dependOn(&docs.step);
    const selected_example = b.option(
        []const u8,
        "example",
        "Example to run (e.g. test or error); omit to run all",
    );

    const example_step = b.step("example", "Build and run all example programs");
    const example_build_step = b.step("build_example", "Build all example programs");
    for ([_][]const u8{
        "examples/color.zig",
        "examples/project_generator.zig",
    }) |path| {
        const name = std.fs.path.stem(path);

        if (selected_example) |selected| {
            if (!std.mem.eql(u8, selected, name)) continue;
        }

        const exe = b.addExecutable(.{ .name = name, .root_module = b.createModule(.{ .root_source_file = b.path(path), .target = target, .optimize = optimize, .imports = &.{.{ .name = "termy", .module = mod }} }) });
        const run = b.addRunArtifact(exe);
        const runi = b.addInstallArtifact(exe, .{});
        example_step.dependOn(&run.step);
        run.stdio = .inherit;
        run.setStdIn(run.stdin);
        example_build_step.dependOn(&runi.step);
    }
    const test_step = b.step("test", "Build and run test example");
    const test_build_step = b.step("build_test", "Build and test example");
    const exe = b.addExecutable(.{
        .name = "test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "termy", .module = mod },
            },
        }),
    });

    const run = b.addRunArtifact(exe);
    const runi = b.addInstallArtifact(exe, .{});
    test_step.dependOn(&run.step);
    test_build_step.dependOn(&runi.step);
}
