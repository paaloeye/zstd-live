const std = @import("std");

pub const ZigVersion = struct {
    name: []const u8,
    tag: []const u8,
    url: []const u8,
    description: []const u8,
};

pub const SUPPORTED_VERSIONS = [_]ZigVersion{
    .{
        .name = "0.15.0-master",
        .tag = "master",
        .url = "https://github.com/ziglang/zig/archive/refs/heads/master.tar.gz",
        .description = "Latest development version",
    },
    .{
        .name = "0.14.1",
        .tag = "0.14.1",
        .url = "https://github.com/ziglang/zig/archive/refs/tags/0.14.1.tar.gz",
        .description = "Latest stable release",
    },
    .{
        .name = "0.13.0",
        .tag = "0.13.0",
        .url = "https://github.com/ziglang/zig/archive/refs/tags/0.13.0.tar.gz",
        .description = "Stable release",
    },
    .{
        .name = "0.12.0",
        .tag = "0.12.0",
        .url = "https://github.com/ziglang/zig/archive/refs/tags/0.12.0.tar.gz",
        .description = "Stable release",
    },
    .{
        .name = "0.11.0",
        .tag = "0.11.0",
        .url = "https://github.com/ziglang/zig/archive/refs/tags/0.11.0.tar.gz",
        .description = "Stable release",
    },
};

pub const Config = struct {
    cache_dir: []const u8,
    output_dir: []const u8,
    port: u16,

    pub fn default(allocator: std.mem.Allocator) !Config {
        const home = std.posix.getenv("HOME") orelse ".";
        const cache_dir = try std.fs.path.join(allocator, &.{ home, ".local", "share", "zstd-live", "sources" });

        return Config{
            .cache_dir = cache_dir,
            .output_dir = "dist",
            .port = 8080,
        };
    }

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.cache_dir);
    }
};

pub fn findVersionByName(name: []const u8) ?ZigVersion {
    for (SUPPORTED_VERSIONS) |version| {
        if (std.mem.eql(u8, version.name, name)) {
            return version;
        }
    }
    return null;
}

test "config basic functionality" {
    const allocator = std.testing.allocator;

    // Test version lookup
    const version = findVersionByName("0.14.1");
    try std.testing.expect(version != null);
    try std.testing.expectEqualStrings("Latest stable release", version.?.description);

    // Test master version lookup
    const master_version = findVersionByName("0.15.0-master");
    try std.testing.expect(master_version != null);
    try std.testing.expectEqualStrings("Latest development version", master_version.?.description);

    // Test config creation
    var config = try Config.default(allocator);
    defer config.deinit(allocator);

    try std.testing.expect(config.port == 8080);
    try std.testing.expectEqualStrings("dist", config.output_dir);
}
