const std = @import("std");
const config = @import("config.zig");
const parser = @import("parser.zig");
const template = @import("template.zig");
const version_manager = @import("version_manager.zig");
const file_utils = @import("file_utils.zig");

pub const Generator = struct {
    allocator: std.mem.Allocator,
    config: config.Config,
    version_manager: version_manager.VersionManager,
    file_utils: file_utils.FileUtils,
    template: template.HtmlTemplate,

    pub fn init(allocator: std.mem.Allocator, cfg: config.Config) Generator {
        return Generator{
            .allocator = allocator,
            .config = cfg,
            .version_manager = version_manager.VersionManager.init(allocator, cfg),
            .file_utils = file_utils.FileUtils.init(allocator),
            .template = template.HtmlTemplate.init(allocator),
        };
    }

    pub fn generateAll(self: *Generator) !void {
        std.log.info("Generating documentation for all supported versions...", .{});

        for (config.SUPPORTED_VERSIONS) |version| {
            try self.generateVersion(version);
        }

        // Generate index page
        try self.generateIndex();

        // Copy static assets
        try self.copyAssets();

        std.log.info("Documentation generation completed!", .{});
    }

    pub fn generateVersion(self: *Generator, version: config.ZigVersion) !void {
        std.log.info("Generating documentation for Zig {s}...", .{version.name});

        // Ensure version is available
        const version_path = try self.version_manager.ensureVersion(version);
        defer self.allocator.free(version_path);

        // Get stdlib path
        const stdlib_path = try self.version_manager.getStdlibPath(version.name);
        defer self.allocator.free(stdlib_path);

        if (!self.file_utils.pathExists(stdlib_path)) {
            std.log.err("Stdlib path not found: {s}", .{stdlib_path});
            return error.StdlibNotFound;
        }

        // Create output directory for this version
        const version_output = try std.fs.path.join(self.allocator, &.{ self.config.output_dir, version.name });
        defer self.allocator.free(version_output);

        try self.file_utils.ensureDir(version_output);

        // Process all .zig files directly

        // Process files directly
        try self.processAllZigFiles(stdlib_path, version.name, version_output);

        std.log.info("Generated documentation for Zig {s}", .{version.name});
    }

    fn processAllZigFiles(self: *Generator, stdlib_path: []const u8, version_name: []const u8, output_dir: []const u8) !void {
        try self.walkAndProcessDirectory(stdlib_path, "", stdlib_path, version_name, output_dir);
    }

    fn walkAndProcessDirectory(self: *Generator, base_path: []const u8, rel_path: []const u8, stdlib_path: []const u8, version_name: []const u8, output_dir: []const u8) !void {
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
                        try self.processZigFile(full_path, entry_rel_path, version_name, output_dir);
                    }
                },
                .directory => {
                    try self.walkAndProcessDirectory(base_path, entry_rel_path, stdlib_path, version_name, output_dir);
                },
                else => {},
            }
        }
    }

    fn processZigFile(self: *Generator, file_path: []const u8, rel_path: []const u8, version_name: []const u8, output_dir: []const u8) !void {
        // Read file content
        const content = self.file_utils.readFile(file_path) catch |err| {
            std.log.warn("Failed to read {s}: {}", .{ file_path, err });
            return;
        };
        defer self.allocator.free(content);

        // Parse the file
        var zig_parser = parser.ZigParser.init(self.allocator);
        var parse_result = zig_parser.parseFile(content) catch |err| {
            std.log.warn("Failed to parse {s}: {}", .{ file_path, err });
            return;
        };
        defer parse_result.deinit();

        // Split content into lines for template
        var lines = std.ArrayList([]const u8).init(self.allocator);
        defer lines.deinit();

        var line_iterator = std.mem.splitScalar(u8, content, '\n');
        while (line_iterator.next()) |line| {
            try lines.append(line);
        }

        // Calculate relative root path (accounting for version directory)
        const version_relative_path = try std.fs.path.join(self.allocator, &.{ version_name, rel_path });
        defer self.allocator.free(version_relative_path);
        const root_rel_link = try self.file_utils.calculateRelativeRoot(version_relative_path);
        defer self.allocator.free(root_rel_link);

        // Get current timestamp
        const timestamp = try self.file_utils.getCurrentTimestamp();
        defer self.allocator.free(timestamp);

        // Create template context
        const context = template.TemplateContext{
            .filename = std.fs.path.basename(file_path),
            .relative_path = rel_path,
            .version = version_name,
            .root_rel_link = root_rel_link,
            .doc_comments = parse_result.doc_comments.items,
            .declarations = parse_result.declarations.items,
            .source_lines = lines.items,
            .generation_time = timestamp,
        };

        // Generate HTML
        const html = try self.template.renderPage(context);
        defer self.allocator.free(html);

        // Write output file
        const output_filename = try std.fmt.allocPrint(self.allocator, "{s}.html", .{rel_path});
        defer self.allocator.free(output_filename);

        const output_path = try std.fs.path.join(self.allocator, &.{ output_dir, output_filename });
        defer self.allocator.free(output_path);

        try self.file_utils.writeFile(output_path, html);

        if (std.mem.eql(u8, std.fs.path.basename(rel_path), "std.zig")) {
            std.log.info("  Generated {s}/std.zig.html", .{version_name});
        }
    }

    pub fn generateIndex(self: *Generator) !void {
        std.log.info("Generating index page...", .{});

        // Get available versions
        const versions = try self.version_manager.listAvailableVersions();
        defer {
            for (versions) |version| {
                self.allocator.free(version);
            }
            self.allocator.free(versions);
        }

        // Generate index HTML
        const index_html = try self.template.renderIndex(versions);
        defer self.allocator.free(index_html);

        // Write index file
        const index_path = try std.fs.path.join(self.allocator, &.{ self.config.output_dir, "index.html" });
        defer self.allocator.free(index_path);

        try self.file_utils.writeFile(index_path, index_html);

        std.log.info("Generated index.html", .{});
    }

    pub fn copyAssets(self: *Generator) !void {
        std.log.info("Copying static assets...", .{});

        // Ensure assets directory exists
        const assets_dir = try std.fs.path.join(self.allocator, &.{ self.config.output_dir, "assets" });
        defer self.allocator.free(assets_dir);

        try self.file_utils.ensureDir(assets_dir);

        // Copy CSS file
        if (self.file_utils.pathExists("assets/styles.css")) {
            const css_dest = try std.fs.path.join(self.allocator, &.{ assets_dir, "styles.css" });
            defer self.allocator.free(css_dest);
            try self.file_utils.copyFile("assets/styles.css", css_dest);
        }

        // Copy SVG file
        if (self.file_utils.pathExists("assets/zig-stdlib-book.svg")) {
            const svg_dest = try std.fs.path.join(self.allocator, &.{ assets_dir, "zig-stdlib-book.svg" });
            defer self.allocator.free(svg_dest);
            try self.file_utils.copyFile("assets/zig-stdlib-book.svg", svg_dest);
        }

        std.log.info("Copied static assets", .{});
    }

    pub fn serve(self: *Generator, port: u16) !void {
        // Simple HTTP server implementation would go here
        // For now, just a placeholder
        std.log.info("HTTP server functionality not implemented yet", .{});
        std.log.info("You can serve the generated files manually:", .{});
        std.log.info("  cd {s} && python -m http.server {d}", .{ self.config.output_dir, port });

        return error.NotImplemented;
    }

    pub fn clean(self: *Generator) !void {
        try self.file_utils.deleteRecursive(self.config.output_dir);
        std.log.info("Cleaned output directory: {s}", .{self.config.output_dir});
    }
};

test "generator basic functionality" {
    const allocator = std.testing.allocator;

    var cfg = try config.Config.default(allocator);
    defer cfg.deinit(allocator);

    const generator = Generator.init(allocator, cfg);

    // Test basic initialization
    try std.testing.expect(generator.allocator == allocator);
}
