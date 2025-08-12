const std = @import("std");
const config = @import("config.zig");
const generator = @import("generator.zig");
const version_manager = @import("version_manager.zig");

// NB: debug messages are optimised out in compile time
pub const std_options: std.Options = .{
    .log_level = .info,
};

const Command = enum {
    generate,
    serve,
    update,
    clean,
    help,
    version,
};

const Args = struct {
    command: Command,
    version_name: ?[]const u8 = null,
    all_versions: bool = false,
    output_dir: ?[]const u8 = null,
    port: ?u16 = null,

    pub fn parse(_allocator: std.mem.Allocator, args: [][:0]u8) !Args {
        if (args.len < 2) {
            return Args{ .command = .help };
        }

        const command_str = args[1];
        const cmd = std.meta.stringToEnum(Command, command_str) orelse {
            std.log.err("Unknown command: {s}", .{command_str});
            return Args{ .command = .help };
        };

        var result = Args{ .command = cmd };

        var i: usize = 2;
        while (i < args.len) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, "--version") and i + 1 < args.len) {
                result.version_name = args[i + 1];
                i += 2;
            } else if (std.mem.eql(u8, arg, "--all-versions")) {
                result.all_versions = true;
                i += 1;
            } else if (std.mem.eql(u8, arg, "--output") and i + 1 < args.len) {
                result.output_dir = args[i + 1];
                i += 2;
            } else if (std.mem.eql(u8, arg, "--port") and i + 1 < args.len) {
                result.port = std.fmt.parseInt(u16, args[i + 1], 10) catch {
                    std.log.err("Invalid port number: {s}", .{args[i + 1]});
                    return Args{ .command = .help };
                };
                i += 2;
            } else {
                std.log.warn("Unknown argument: {s}", .{arg});
                i += 1;
            }
        }

        _ = _allocator; // Suppress unused parameter warning
        return result;
    }
};

fn printHelp() void {
    const help_text =
        \\zstd-live - Generate live HTML documentation from Zig standard library
        \\
        \\USAGE:
        \\    zstd-live <COMMAND> [OPTIONS]
        \\
        \\COMMANDS:
        \\    generate         Generate documentation
        \\    serve           Serve documentation locally (development server)
        \\    update          Update Zig stdlib sources
        \\    clean           Clean generated files and cache
        \\    version         Show version information
        \\    help            Show this help message
        \\
        \\OPTIONS:
        \\    --version <VERSION>    Generate docs for specific Zig version
        \\    --all-versions         Generate docs for all supported versions
        \\    --output <DIR>         Output directory (default: dist)
        \\    --port <PORT>          Port for development server (default: 8080)
        \\
        \\EXAMPLES:
        \\    zstd-live generate --all-versions
        \\    zstd-live generate --version 0.14.1 --output ./docs
        \\    zstd-live serve --port 3000
        \\    zstd-live update
        \\
        \\SUPPORTED VERSIONS:
    ;

    std.log.info("{s}", .{help_text});
    for (config.SUPPORTED_VERSIONS) |version| {
        std.log.info("    {s} - {s}", .{ version.name, version.description });
    }
}

fn printVersion() void {
    const version_info =
        \\zstd-live 2.0.0
        \\
        \\A modern Zig-native tool for generating live HTML documentation
        \\from Zig standard library source code.
        \\
        \\Repository: https://github.com/paaloeye/zstd-live
        \\Live Site:  https://zstd-live.pages.dev
        \\
        \\Built with Zig
    ;

    std.log.info("{s}", .{version_info});
}

fn runGenerate(allocator: std.mem.Allocator, args: Args) !void {
    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    // Override output directory if specified
    if (args.output_dir) |output| {
        // Note: In a real implementation, we'd need to handle memory management better
        cfg.output_dir = output;
    }

    var gen = generator.Generator.init(allocator, cfg);

    if (args.all_versions) {
        try gen.generateAll();
    } else if (args.version_name) |version_name| {
        const version = config.findVersionByName(version_name) orelse {
            std.log.err("Unsupported version: {s}", .{version_name});
            std.log.info("Supported versions:", .{});
            for (config.SUPPORTED_VERSIONS) |v| {
                std.log.info("  {s}", .{v.name});
            }
            return;
        };

        try gen.generateVersion(version);
        try gen.generateIndex();
        try gen.copyAssets();
    } else {
        std.log.err("Please specify --version <VERSION> or --all-versions", .{});
        return;
    }
}

fn runServe(allocator: std.mem.Allocator, args: Args) !void {
    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    const port = args.port orelse cfg.port;

    var gen = generator.Generator.init(allocator, cfg);
    try gen.serve(port);
}

fn runUpdate(allocator: std.mem.Allocator, args: Args) !void {
    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    var vm = version_manager.VersionManager.init(allocator, cfg);

    if (args.version_name) |version_name| {
        const version = config.findVersionByName(version_name) orelse {
            std.log.err("Unsupported version: {s}", .{version_name});
            return;
        };

        try vm.updateVersion(version);
    } else {
        try vm.updateAllVersions();
    }
}

fn runClean(allocator: std.mem.Allocator, args: Args) !void {
    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    var gen = generator.Generator.init(allocator, cfg);
    try gen.clean();

    // Also clean version manager cache if requested
    var vm = version_manager.VersionManager.init(allocator, cfg);

    std.log.info("Also clean download cache? (y/N): ", .{});
    const stdin = std.io.getStdIn().reader();

    var buffer: [10]u8 = undefined;
    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| {
        const trimmed = std.mem.trim(u8, input, " \t\r\n");
        if (std.mem.eql(u8, trimmed, "y") or std.mem.eql(u8, trimmed, "Y")) {
            try vm.cleanCache();
        }
    }

    _ = args; // Suppress unused parameter warning
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const parsed_args = Args.parse(allocator, args) catch {
        printHelp();
        return;
    };

    switch (parsed_args.command) {
        .generate => runGenerate(allocator, parsed_args) catch |err| {
            std.log.err("Generation failed: {}", .{err});
            std.process.exit(1);
        },
        .serve => runServe(allocator, parsed_args) catch |err| {
            std.log.err("Server failed: {}", .{err});
            std.process.exit(1);
        },
        .update => runUpdate(allocator, parsed_args) catch |err| {
            std.log.err("Update failed: {}", .{err});
            std.process.exit(1);
        },
        .clean => runClean(allocator, parsed_args) catch |err| {
            std.log.err("Clean failed: {}", .{err});
            std.process.exit(1);
        },
        .version => printVersion(),
        .help => printHelp(),
    }
}

test "basic functionality" {
    // Test version lookup functionality
    const version = config.findVersionByName("0.14.1");
    try std.testing.expect(version != null);
    try std.testing.expectEqualStrings("Latest stable release", version.?.description);
}
