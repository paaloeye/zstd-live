const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "zstd-live",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // Format check
    const fmt_step = b.step("fmt", "Format source code");
    const fmt = b.addFmt(.{
        .paths = &.{"src"},
        .check = false,
    });
    fmt_step.dependOn(&fmt.step);

    // Check formatting
    const check_fmt_step = b.step("check-fmt", "Check source code formatting");
    const check_fmt = b.addFmt(.{
        .paths = &.{"src"},
        .check = true,
    });
    check_fmt_step.dependOn(&check_fmt.step);

    // Build release step
    //
    // Ref: https://zig.guide/master/build-system/cross-compilation
    //
    const SupportedTarget = struct {
        os: std.Target.Os.Tag,
        arch: std.Target.Cpu.Arch,
    };

    const supported_targets = [_]SupportedTarget{
        .{ .os = .macos, .arch = .x86_64 },
        .{ .os = .macos, .arch = .aarch64 },
        .{ .os = .linux, .arch = .x86_64 },
        .{ .os = .linux, .arch = .aarch64 },
        .{ .os = .linux, .arch = .riscv64 },
        .{ .os = .windows, .arch = .x86_64 },
        .{ .os = .windows, .arch = .aarch64 },
    };

    const build_release = b.step("release", "Build all supported OS and ARCH");

    for (supported_targets) |release_combo| {
        const release_target = b.resolveTargetQuery(.{
            .cpu_arch = release_combo.arch,
            .os_tag = release_combo.os,
        });

        const os_name = switch (release_combo.os) {
            .macos => "macos",
            .linux => "linux",
            .windows => "windows",
            else => unreachable,
        };

        const arch_name = switch (release_combo.arch) {
            .x86_64 => "x86_64",
            .aarch64 => "aarch64",
            .riscv64 => "riscv64",
            else => unreachable,
        };

        const release_name = b.fmt("zstd-live-{s}-{s}", .{ os_name, arch_name });

        const release_exe = b.addExecutable(.{
            .name = release_name,
            .root_source_file = b.path("src/main.zig"),
            .target = release_target,
            .optimize = .ReleaseFast,
        });

        const install_release = b.addInstallArtifact(release_exe, .{});
        build_release.dependOn(&install_release.step);
    }
}
