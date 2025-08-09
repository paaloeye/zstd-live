const std = @import("std");

pub const FileUtils = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) FileUtils {
        return FileUtils{ .allocator = allocator };
    }

    pub fn ensureDir(self: *FileUtils, path: []const u8) !void {
        _ = self; // FileUtils instance not needed for this operation
        std.fs.cwd().makePath(path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }

    pub fn copyFile(self: *FileUtils, source: []const u8, dest: []const u8) !void {
        const source_file = try std.fs.cwd().openFile(source, .{});
        defer source_file.close();

        // Ensure destination directory exists
        if (std.fs.path.dirname(dest)) |dir| {
            try self.ensureDir(dir);
        }

        const dest_file = try std.fs.cwd().createFile(dest, .{});
        defer dest_file.close();

        const source_size = try source_file.getEndPos();
        _ = try source_file.copyRangeAll(0, dest_file, 0, source_size);
    }

    pub fn readFile(self: *FileUtils, path: []const u8) ![]u8 {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const contents = try self.allocator.alloc(u8, file_size);
        _ = try file.readAll(contents);

        return contents;
    }

    pub fn writeFile(self: *FileUtils, path: []const u8, content: []const u8) !void {

        // Ensure directory exists
        if (std.fs.path.dirname(path)) |dir| {
            try self.ensureDir(dir);
        }

        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        try file.writeAll(content);
    }

    pub fn findZigFiles(self: *FileUtils, base_path: []const u8, callback: *const fn ([]const u8, []const u8) anyerror!void) !void {
        try self.walkDirectory(base_path, "", callback);
    }

    fn walkDirectory(self: *FileUtils, base_path: []const u8, rel_path: []const u8, callback: *const fn ([]const u8, []const u8) anyerror!void) !void {
        const current_path = if (rel_path.len == 0)
            try self.allocator.dupe(u8, base_path)
        else
            try std.fs.path.join(self.allocator, &.{ base_path, rel_path });
        defer self.allocator.free(current_path);

        var dir = std.fs.cwd().openDir(current_path, .{ .iterate = true }) catch |err| switch (err) {
            error.FileNotFound, error.NotDir => return,
            else => return err,
        };
        defer dir.close();

        var iterator = dir.iterate();

        while (try iterator.next()) |entry| {
            // Skip zig-cache directories
            if (std.mem.eql(u8, entry.name, "zig-cache")) continue;

            const entry_rel_path = if (rel_path.len == 0)
                try self.allocator.dupe(u8, entry.name)
            else
                try std.fs.path.join(self.allocator, &.{ rel_path, entry.name });
            defer self.allocator.free(entry_rel_path);

            const full_path = try std.fs.path.join(self.allocator, &.{ base_path, entry_rel_path });
            defer self.allocator.free(full_path);

            switch (entry.kind) {
                .file => {
                    if (std.mem.endsWith(u8, entry.name, ".zig")) {
                        try callback(full_path, entry_rel_path);
                    }
                },
                .directory => {
                    try self.walkDirectory(base_path, entry_rel_path, callback);
                },
                else => {},
            }
        }
    }

    pub fn calculateRelativeRoot(self: *FileUtils, relative_path: []const u8) ![]u8 {
        const separator_count = std.mem.count(u8, relative_path, "/");

        if (separator_count == 0) {
            return try self.allocator.dupe(u8, "");
        }

        const root_rel = try self.allocator.alloc(u8, separator_count * 3); // "../" for each level
        var pos: usize = 0;

        for (0..separator_count) |_| {
            @memcpy(root_rel[pos .. pos + 3], "../");
            pos += 3;
        }

        return root_rel;
    }

    pub fn pathExists(self: *FileUtils, path: []const u8) bool {
        _ = self;
        std.fs.cwd().access(path, .{}) catch return false;
        return true;
    }

    pub fn deleteRecursive(self: *FileUtils, path: []const u8) !void {
        _ = self;
        std.fs.cwd().deleteTree(path) catch {};
    }

    pub fn getCurrentTimestamp(self: *FileUtils) ![]u8 {
        const timestamp = std.time.timestamp();
        const datetime = std.time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
        const day_seconds = datetime.getDaySeconds();
        const epoch_day = datetime.getEpochDay();
        const year_day = epoch_day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();

        return try std.fmt.allocPrint(self.allocator, "{d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2} UTC", .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
        });
    }
};

test "file utils basic functionality" {
    const allocator = std.testing.allocator;
    var utils = FileUtils.init(allocator);

    // Test relative root calculation
    const root1 = try utils.calculateRelativeRoot("file.zig");
    defer allocator.free(root1);
    try std.testing.expectEqualStrings("", root1);

    const root2 = try utils.calculateRelativeRoot("dir/file.zig");
    defer allocator.free(root2);
    try std.testing.expectEqualStrings("../", root2);

    const root3 = try utils.calculateRelativeRoot("dir1/dir2/file.zig");
    defer allocator.free(root3);
    try std.testing.expectEqualStrings("../../", root3);

    // Test timestamp generation
    const timestamp = try utils.getCurrentTimestamp();
    defer allocator.free(timestamp);
    try std.testing.expect(timestamp.len > 0);
}
