const std = @import("std");
const config = @import("config.zig");
const file_utils = @import("file_utils.zig");

pub const VersionManager = struct {
    allocator: std.mem.Allocator,
    config: config.Config,
    file_utils: file_utils.FileUtils,

    pub fn init(allocator: std.mem.Allocator, cfg: config.Config) VersionManager {
        return VersionManager{
            .allocator = allocator,
            .config = cfg,
            .file_utils = file_utils.FileUtils.init(allocator),
        };
    }

    pub fn ensureVersion(self: *VersionManager, version: config.ZigVersion) ![]u8 {
        const version_dir = try self.getVersionPath(version.name);

        if (!self.file_utils.pathExists(version_dir)) {
            std.log.info("Downloading Zig {s}...", .{version.name});
            try self.downloadAndExtractVersion(version);
        } else {
            std.log.info("Using cached Zig {s}", .{version.name});
        }

        return version_dir;
    }

    pub fn getVersionPath(self: *VersionManager, version_name: []const u8) ![]u8 {
        return try std.fs.path.join(self.allocator, &.{ self.config.cache_dir, version_name });
    }

    pub fn getStdlibPath(self: *VersionManager, version_name: []const u8) ![]u8 {
        const version_path = try self.getVersionPath(version_name);
        defer self.allocator.free(version_path);

        // Try different possible stdlib locations
        const possible_paths = [_][]const u8{
            "lib/std",
            "zig-master/lib/std",
            "zig-0.14.1/lib/std",
            "zig-0.14.0/lib/std",
        };

        for (possible_paths) |subpath| {
            const stdlib_path = try std.fs.path.join(self.allocator, &.{ version_path, subpath });

            if (self.file_utils.pathExists(stdlib_path)) {
                return stdlib_path;
            }

            self.allocator.free(stdlib_path);
        }

        // Fallback: assume direct lib/std structure
        return try std.fs.path.join(self.allocator, &.{ version_path, "lib", "std" });
    }

    fn downloadAndExtractVersion(self: *VersionManager, version: config.ZigVersion) !void {
        try self.file_utils.ensureDir(self.config.cache_dir);

        const version_dir = try self.getVersionPath(version.name);
        defer self.allocator.free(version_dir);

        // Create temporary file for download
        const temp_file = try std.fs.path.join(self.allocator, &.{ self.config.cache_dir, "temp.tar.gz" });
        defer self.allocator.free(temp_file);

        // Download using curl (simple approach for now)
        const download_cmd = try std.fmt.allocPrint(self.allocator, "curl -L \"{s}\" -o \"{s}\"", .{ version.url, temp_file });
        defer self.allocator.free(download_cmd);

        var download_process = std.process.Child.init(&.{ "sh", "-c", download_cmd }, self.allocator);
        download_process.stdout_behavior = .Ignore;
        download_process.stderr_behavior = .Ignore;

        const download_result = try download_process.spawnAndWait();
        if (download_result != .Exited or download_result.Exited != 0) {
            return error.DownloadFailed;
        }

        // Extract using tar
        const extract_cmd = try std.fmt.allocPrint(self.allocator, "mkdir -p \"{s}\" && tar -xzf \"{s}\" -C \"{s}\" --strip-components=1", .{ version_dir, temp_file, version_dir });
        defer self.allocator.free(extract_cmd);

        var extract_process = std.process.Child.init(&.{ "sh", "-c", extract_cmd }, self.allocator);
        extract_process.stdout_behavior = .Ignore;
        extract_process.stderr_behavior = .Ignore;

        const extract_result = try extract_process.spawnAndWait();
        if (extract_result != .Exited or extract_result.Exited != 0) {
            return error.ExtractionFailed;
        }

        // Cleanup temp file
        std.fs.cwd().deleteFile(temp_file) catch {};

        std.log.info("Successfully downloaded and extracted Zig {s}", .{version.name});
    }

    pub fn listAvailableVersions(self: *VersionManager) ![][]const u8 {
        var available = std.ArrayList([]const u8).init(self.allocator);

        for (config.SUPPORTED_VERSIONS) |version| {
            const version_path = try self.getVersionPath(version.name);
            defer self.allocator.free(version_path);

            if (self.file_utils.pathExists(version_path)) {
                try available.append(try self.allocator.dupe(u8, version.name));
            }
        }

        return available.toOwnedSlice();
    }

    pub fn updateVersion(self: *VersionManager, version: config.ZigVersion) !void {
        const version_path = try self.getVersionPath(version.name);
        defer self.allocator.free(version_path);

        // Remove existing version
        try self.file_utils.deleteRecursive(version_path);

        // Re-download
        try self.downloadAndExtractVersion(version);
    }

    pub fn updateAllVersions(self: *VersionManager) !void {
        for (config.SUPPORTED_VERSIONS) |version| {
            std.log.info("Updating {s}...", .{version.name});
            self.updateVersion(version) catch |err| {
                std.log.err("Failed to update {s}: {}", .{ version.name, err });
                continue;
            };
        }
    }

    pub fn cleanCache(self: *VersionManager) !void {
        try self.file_utils.deleteRecursive(self.config.cache_dir);
        std.log.info("Cache cleaned", .{});
    }

    pub fn getCacheSize(self: *VersionManager) !u64 {
        var total_size: u64 = 0;

        var cache_dir = std.fs.cwd().openDir(self.config.cache_dir, .{ .iterate = true }) catch return 0;
        defer cache_dir.close();

        var walker = try cache_dir.walk(self.allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file) {
                const stat = try entry.dir.statFile(entry.basename);
                total_size += stat.size;
            }
        }

        return total_size;
    }

    pub fn formatCacheSize(self: *VersionManager, size: u64) ![]u8 {
        const units = [_][]const u8{ "B", "KB", "MB", "GB" };
        var size_f: f64 = @floatFromInt(size);
        var unit_index: usize = 0;

        while (size_f >= 1024.0 and unit_index < units.len - 1) {
            size_f /= 1024.0;
            unit_index += 1;
        }

        return try std.fmt.allocPrint(self.allocator, "{d:.1} {s}", .{ size_f, units[unit_index] });
    }
};

test "version manager basic functionality" {
    const allocator = std.testing.allocator;

    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    var vm = VersionManager.init(allocator, cfg);

    // Test path generation
    const version_path = try vm.getVersionPath("0.14.1");
    defer allocator.free(version_path);
    try std.testing.expect(std.mem.indexOf(u8, version_path, "0.14.1") != null);

    // Test cache size formatting
    const formatted = try vm.formatCacheSize(1536);
    defer allocator.free(formatted);
    try std.testing.expectEqualStrings("1.5 KB", formatted);
}
