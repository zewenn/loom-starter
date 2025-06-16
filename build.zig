const std = @import("std");

const fs = std.fs;
const Allocator = std.mem.Allocator;

const exe_name = "loom_starter";
const debug_asset_path = "src/assets/";
const release_asset_path = "assets/";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const loom_dep = b.dependency("loom", .{
        .target = target,
        .optimize = optimize,
    });
    const loom_mod = loom_dep.module("loom");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addCMacro("LOOM_DEBUG_ASSET_PATH", "\"" ++ debug_asset_path ++ "\"");
    exe_mod.addCMacro("LOOM_RELEASE_ASSET_PATH", "\"" ++ release_asset_path ++ "\"");

    exe_mod.addImport("loom", loom_mod);

    if (optimize != .Debug) {
        const cwd = try fs.realpathAlloc(std.heap.smp_allocator, ".");
        defer std.heap.smp_allocator.free(cwd);

        const src_path = try fs.path.join(std.heap.smp_allocator, &.{
            cwd,
            debug_asset_path,
        });
        defer std.heap.smp_allocator.free(src_path);

        const dest_path = try fs.path.join(std.heap.smp_allocator, &.{
            cwd,
            "zig-out/bin/" ++ release_asset_path,
        });
        defer std.heap.smp_allocator.free(src_path);

        try copyDir(
            std.heap.smp_allocator,
            src_path,
            dest_path,
        );
    }

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = exe_mod,
        .use_llvm = true,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

pub fn copyDir(allocator: Allocator, src_path: []const u8, dest_path: []const u8) !void {
    if (fs.accessAbsolute(dest_path, .{})) |_| {
        try fs.deleteTreeAbsolute(dest_path);
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => |e| return e,
    }

    try fs.makeDirAbsolute(dest_path);

    var src_dir = try fs.openDirAbsolute(src_path, .{ .iterate = true });
    defer src_dir.close();

    var iter = src_dir.iterate();

    while (try iter.next()) |entry| {
        const src_entry_path = try fs.path.join(allocator, &.{ src_path, entry.name });
        defer allocator.free(src_entry_path);

        const dest_entry_path = try fs.path.join(allocator, &.{ dest_path, entry.name });
        defer allocator.free(dest_entry_path);

        switch (entry.kind) {
            .file => try fs.copyFileAbsolute(src_entry_path, dest_entry_path, .{}),
            .directory => try copyDir(allocator, src_entry_path, dest_entry_path),
            else => std.log.warn("entry of kind \"{any}\" cannot be copied. ({s})", .{ entry.kind, entry.name }),
        }
    }
}
