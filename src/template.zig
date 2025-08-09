const std = @import("std");
const parser = @import("parser.zig");

pub const ModuleInfo = struct {
    name: []const u8,
    file: []const u8,
    description: []const u8,
};

pub const CategoryInfo = struct {
    name: []const u8,
    description: []const u8,
    modules: []const ModuleInfo,
};

pub const STDLIB_CATEGORIES = [_]CategoryInfo{
    .{
        .name = "Data Structures",
        .description = "Core data structures and containers",
        .modules = &[_]ModuleInfo{
            .{ .name = "ArrayList", .file = "array_list.zig", .description = "Dynamic array that can grow and shrink" },
            .{ .name = "ArrayHashMap", .file = "array_hash_map.zig", .description = "Hash map backed by a flat array" },
            .{ .name = "HashMap", .file = "hash_map.zig", .description = "General purpose hash map" },
            .{ .name = "MultiArrayList", .file = "multi_array_list.zig", .description = "Structure of arrays for better cache locality" },
            .{ .name = "LinkedList", .file = "linked_list.zig", .description = "Doubly-linked list implementation" },
            .{ .name = "SinglyLinkedList", .file = "SinglyLinkedList.zig", .description = "Singly-linked list implementation" },
        },
    },
    .{
        .name = "Memory & Allocation",
        .description = "Memory management and allocators",
        .modules = &[_]ModuleInfo{
            .{ .name = "mem", .file = "mem.zig", .description = "Memory manipulation utilities" },
            .{ .name = "heap", .file = "heap.zig", .description = "Heap memory allocators" },
            .{ .name = "Allocator", .file = "mem/Allocator.zig", .description = "Memory allocator interface" },
        },
    },
    .{
        .name = "Zig-Specific",
        .description = "Core Zig language features and introspection",
        .modules = &[_]ModuleInfo{
            .{ .name = "std", .file = "std.zig", .description = "Standard library root" },
            .{ .name = "builtin", .file = "builtin.zig", .description = "Built-in compile-time information" },
            .{ .name = "meta", .file = "meta.zig", .description = "Metaprogramming utilities" },
            .{ .name = "testing", .file = "testing.zig", .description = "Unit testing framework" },
            .{ .name = "debug", .file = "debug.zig", .description = "Debugging utilities and stack traces" },
            .{ .name = "Build", .file = "Build.zig", .description = "Build system API" },
        },
    },
    .{
        .name = "General Utilities",
        .description = "Common utilities and algorithms",
        .modules = &[_]ModuleInfo{
            .{ .name = "fmt", .file = "fmt.zig", .description = "String formatting and parsing" },
            .{ .name = "json", .file = "json.zig", .description = "JSON parsing and stringification" },
            .{ .name = "log", .file = "log.zig", .description = "Logging framework" },
            .{ .name = "sort", .file = "sort.zig", .description = "Sorting algorithms" },
            .{ .name = "math", .file = "math.zig", .description = "Mathematical functions and constants" },
            .{ .name = "ascii", .file = "ascii.zig", .description = "ASCII character utilities" },
            .{ .name = "unicode", .file = "unicode.zig", .description = "Unicode utilities" },
        },
    },
    .{
        .name = "I/O & File System",
        .description = "Input/output and file system operations",
        .modules = &[_]ModuleInfo{
            .{ .name = "fs", .file = "fs.zig", .description = "File system operations" },
            .{ .name = "io", .file = "io.zig", .description = "Input/output utilities" },
            .{ .name = "tar", .file = "tar.zig", .description = "TAR archive format support" },
            .{ .name = "compress", .file = "compress.zig", .description = "Compression algorithms" },
        },
    },
    .{
        .name = "OS & Platform",
        .description = "Operating system and platform-specific code",
        .modules = &[_]ModuleInfo{
            .{ .name = "os", .file = "os.zig", .description = "Operating system interface" },
            .{ .name = "process", .file = "process.zig", .description = "Process spawning and management" },
            .{ .name = "Thread", .file = "Thread.zig", .description = "Threading primitives" },
            .{ .name = "time", .file = "time.zig", .description = "Time measurement and utilities" },
            .{ .name = "Target", .file = "Target.zig", .description = "Compilation target information" },
        },
    },
    .{
        .name = "Networking",
        .description = "Network programming utilities",
        .modules = &[_]ModuleInfo{
            .{ .name = "net", .file = "net.zig", .description = "Networking primitives" },
            .{ .name = "http", .file = "http.zig", .description = "HTTP client and server" },
            .{ .name = "Uri", .file = "Uri.zig", .description = "URI parsing and manipulation" },
        },
    },
    .{
        .name = "Cryptography",
        .description = "Cryptographic algorithms and utilities",
        .modules = &[_]ModuleInfo{
            .{ .name = "crypto", .file = "crypto.zig", .description = "Cryptographic functions" },
            .{ .name = "hash", .file = "hash.zig", .description = "Hashing algorithms" },
            .{ .name = "Random", .file = "Random.zig", .description = "Random number generation" },
        },
    },
    .{
        .name = "Concurrency",
        .description = "Concurrent and parallel programming",
        .modules = &[_]ModuleInfo{
            .{ .name = "atomic", .file = "atomic.zig", .description = "Atomic operations" },
            .{ .name = "once", .file = "once.zig", .description = "One-time initialization" },
        },
    },
};

pub const TemplateContext = struct {
    filename: []const u8,
    relative_path: []const u8,
    version: []const u8,
    root_rel_link: []const u8,
    doc_comments: []parser.DocComment,
    declarations: []parser.Declaration,
    source_lines: [][]const u8,
    generation_time: []const u8,
};

pub const HtmlTemplate = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HtmlTemplate {
        return HtmlTemplate{ .allocator = allocator };
    }

    pub fn renderPage(self: *HtmlTemplate, context: TemplateContext) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);

        // HTML header
        try self.writeHeader(&result, context);

        // Content body with two-column layout
        try self.writeBody(&result, context);

        // HTML footer
        try self.writeFooter(&result, context);

        return result.toOwnedSlice();
    }

    fn writeHeader(self: *HtmlTemplate, writer: *std.ArrayList(u8), context: TemplateContext) !void {
        _ = self;

        try writer.appendSlice("<!DOCTYPE html>\n");
        try writer.appendSlice("<html lang=\"en\">\n");
        try writer.appendSlice("<head>\n");
        try writer.appendSlice("    <meta charset=\"utf-8\">\n");
        try writer.appendSlice("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");

        // Title
        try writer.appendSlice("    <title>");
        try writer.appendSlice(context.relative_path);
        try writer.appendSlice(" - Zig ");
        try writer.appendSlice(context.version);
        try writer.appendSlice(" standard library</title>\n");

        // CSS link
        try writer.appendSlice("    <link rel=\"stylesheet\" href=\"");
        try writer.appendSlice(context.root_rel_link);
        try writer.appendSlice("assets/styles.css\">\n");

        // Meta tags for SEO
        try writer.appendSlice("    <meta name=\"description\" content=\"Zig ");
        try writer.appendSlice(context.version);
        try writer.appendSlice(" standard library documentation for ");
        try writer.appendSlice(context.relative_path);
        try writer.appendSlice("\">\n");

        try writer.appendSlice("</head>\n");
        try writer.appendSlice("<body>\n");
        try writer.appendSlice("<table><tbody>\n");

        // Page header
        try writer.appendSlice("<tr><td class=\"doc\">\n");
        try writer.appendSlice("<h1>\n");
        try writer.appendSlice("  <a href=\"");
        try writer.appendSlice(context.root_rel_link);
        try writer.appendSlice("index.html\">");
        try writer.appendSlice("<img src=\"");
        try writer.appendSlice(context.root_rel_link);
        try writer.appendSlice("assets/zig-stdlib-book.svg\" alt=\"\" width=\"60\"> ");
        try writer.appendSlice("zig/lib/std</a> /\n");
        try writer.appendSlice("  ");
        try writer.appendSlice(context.relative_path);
        try writer.appendSlice("\n");
        try writer.appendSlice("</h1>\n");
    }

    fn writeBody(self: *HtmlTemplate, writer: *std.ArrayList(u8), context: TemplateContext) !void {
        var doc_idx: usize = 0;
        var decl_idx: usize = 0;
        var in_code_block = false;

        for (context.source_lines, 0..) |line, line_no| {
            // Check if this line corresponds to a declaration
            var matching_decl: ?parser.Declaration = null;

            for (context.declarations[decl_idx..]) |decl| {
                if (std.mem.indexOf(u8, decl.line, line) != null) {
                    matching_decl = decl;
                    decl_idx += 1;
                    break;
                }
            }

            // If we have a matching declaration, start a new doc section
            if (matching_decl) |decl| {
                if (in_code_block) {
                    try writer.appendSlice("</pre></td></tr>\n");
                    in_code_block = false;
                }

                try self.writeDeclaration(writer, decl, context);

                // Write any associated documentation
                if (doc_idx < context.doc_comments.len) {
                    const doc = context.doc_comments[doc_idx];
                    try writer.appendSlice("<p>");

                    // Process inline code in documentation
                    var temp_parser = parser.ZigParser.init(self.allocator);
                    const processed_doc = try temp_parser.processInlineCode(doc.content);
                    defer self.allocator.free(processed_doc);

                    try writer.appendSlice(processed_doc);
                    try writer.appendSlice("</p>\n");
                    doc_idx += 1;
                }

                in_code_block = false;
            }

            // Start code block if needed
            if (!in_code_block) {
                in_code_block = true;

                // Write any remaining documentation
                if (doc_idx < context.doc_comments.len and matching_decl == null) {
                    const doc = context.doc_comments[doc_idx];
                    try writer.appendSlice("<p>");

                    var temp_parser = parser.ZigParser.init(self.allocator);
                    const processed_doc = try temp_parser.processInlineCode(doc.content);
                    defer self.allocator.free(processed_doc);

                    try writer.appendSlice(processed_doc);
                    try writer.appendSlice("</p>\n");
                    doc_idx += 1;
                }

                try writer.appendSlice("</td>\n");
                try writer.appendSlice("<td class=\"code\"><pre>\n");
            }

            // Write the source line with HTML escaping
            try self.writeEscapedHtml(writer, line);
            try writer.appendSlice("\n");

            _ = line_no; // Suppress unused variable warning
        }

        // Close final code block
        if (in_code_block) {
            try writer.appendSlice("</pre></td></tr>\n");
        }
    }

    fn writeDeclaration(self: *HtmlTemplate, writer: *std.ArrayList(u8), decl: parser.Declaration, context: TemplateContext) !void {
        _ = self;

        const css_class = switch (decl.type) {
            .pub_const => "value",
            .pub_fn => "",
            .pub_method => "method",
            .test_str, .test_decl => "test-str",
        };

        try writer.appendSlice("<tr><td class=\"doc ");
        try writer.appendSlice(css_class);
        try writer.appendSlice("\">\n");

        switch (decl.type) {
            .pub_const => {
                try writer.appendSlice("<h2>");
                try writer.appendSlice(decl.name);
                try writer.appendSlice("</h2>\n");

                // Add import link if present
                if (decl.import_file) |import_file| {
                    if (std.mem.endsWith(u8, import_file, ".zig")) {
                        try writer.appendSlice("<a href=\"");
                        try writer.appendSlice(import_file);
                        try writer.appendSlice(".html\">");
                        try writer.appendSlice(import_file);
                        try writer.appendSlice("</a>\n");
                    }
                }
            },
            .pub_fn => {
                try writer.appendSlice("<h2>");
                try writer.appendSlice(decl.name);
                try writer.appendSlice("()</h2>\n");
            },
            .pub_method => {
                try writer.appendSlice("<h2>");
                try writer.appendSlice(decl.name);
                try writer.appendSlice("()</h2>\n");
            },
            .test_str => {
                try writer.appendSlice("<h2>Test:</h2><h3>");
                try writer.appendSlice(decl.name);
                try writer.appendSlice("</h3>\n");
            },
            .test_decl => {
                try writer.appendSlice("<h2>Test: ");
                try writer.appendSlice(decl.name);
                try writer.appendSlice("</h2>\n");
            },
        }

        _ = context; // Suppress unused variable warning
    }

    fn writeFooter(self: *HtmlTemplate, writer: *std.ArrayList(u8), context: TemplateContext) !void {
        _ = self;

        try writer.appendSlice("<tr><td class=\"doc\" id=\"footer\">\n");
        try writer.appendSlice("  Generated by <a href=\"https://github.com/paaloeye/zstd-live\">zstd-live</a>\n");
        try writer.appendSlice("  on ");
        try writer.appendSlice(context.generation_time);
        try writer.appendSlice(".\n");
        try writer.appendSlice("</td><td class=\"code\"></td></tr>\n");
        try writer.appendSlice("</tbody></table>\n");
        try writer.appendSlice("</body>\n");
        try writer.appendSlice("</html>\n");
    }

    fn writeEscapedHtml(self: *HtmlTemplate, writer: *std.ArrayList(u8), text: []const u8) !void {
        _ = self;

        for (text) |c| {
            switch (c) {
                '&' => try writer.appendSlice("&amp;"),
                '<' => try writer.appendSlice("&lt;"),
                '>' => try writer.appendSlice("&gt;"),
                '"' => try writer.appendSlice("&quot;"),
                '\'' => try writer.appendSlice("&#39;"),
                else => try writer.append(c),
            }
        }
    }

    pub fn renderIndex(self: *HtmlTemplate, versions: [][]const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);

        try result.appendSlice("<!DOCTYPE html>\n");
        try result.appendSlice("<html lang=\"en\">\n");
        try result.appendSlice("<head>\n");
        try result.appendSlice("    <meta charset=\"utf-8\">\n");
        try result.appendSlice("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        try result.appendSlice("    <title>Zig Standard Library Documentation</title>\n");
        try result.appendSlice("    <link rel=\"stylesheet\" href=\"assets/styles.css\">\n");
        try result.appendSlice("    <style>\n");
        try result.appendSlice("        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; }\n");
        try result.appendSlice("        .container { max-width: 1200px; margin: 0 auto; padding: 2em; }\n");
        try result.appendSlice("        .version-tabs { display: flex; justify-content: center; margin: 2em 0; flex-wrap: wrap; gap: 0.5em; }\n");
        try result.appendSlice("        .version-tab { padding: 0.5em 1em; background: #f8f9fa; border: 1px solid #dee2e6; text-decoration: none; border-radius: 6px; }\n");
        try result.appendSlice("        .version-tab:hover { background: #e9ecef; }\n");
        try result.appendSlice("        .version-tab.active { background: #007acc; color: white; }\n");
        try result.appendSlice("        .categories { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 2em; margin: 2em 0; }\n");
        try result.appendSlice("        .category { background: white; border: 1px solid #e1e5e9; border-radius: 8px; padding: 1.5em; }\n");
        try result.appendSlice("        .category h3 { margin: 0 0 0.5em 0; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 0.5em; }\n");
        try result.appendSlice("        .category-desc { color: #7f8c8d; font-size: 0.9em; margin-bottom: 1em; }\n");
        try result.appendSlice("        .module-list { list-style: none; padding: 0; margin: 0; }\n");
        try result.appendSlice("        .module-item { margin-bottom: 0.75em; }\n");
        try result.appendSlice("        .module-name { font-weight: 600; color: #2c3e50; margin-bottom: 0.25em; }\n");
        try result.appendSlice("        .module-desc { font-size: 0.85em; color: #7f8c8d; }\n");
        try result.appendSlice("        .module-links { margin-top: 0.25em; }\n");
        try result.appendSlice("        .module-link { font-size: 0.8em; color: #3498db; text-decoration: none; margin-right: 0.75em; }\n");
        try result.appendSlice("        .module-link:hover { text-decoration: underline; }\n");
        try result.appendSlice("    </style>\n");
        try result.appendSlice("</head>\n");
        try result.appendSlice("<body>\n");
        try result.appendSlice("<div class=\"container\">\n");
        try result.appendSlice("    <header style=\"text-align: center; margin: 2em 0;\">\n");
        try result.appendSlice("        <img src=\"assets/zig-stdlib-book.svg\" alt=\"Zig Standard Library\" width=\"120\">\n");
        try result.appendSlice("        <h1>Zig Standard Library Documentation</h1>\n");
        try result.appendSlice("        <p>Browse Zig standard library source code with documentation</p>\n");
        try result.appendSlice("    </header>\n");

        // Version tabs
        try result.appendSlice("    <div class=\"version-tabs\">\n");
        for (versions, 0..) |version, i| {
            try result.appendSlice("        <a href=\"");
            try result.appendSlice(version);
            try result.appendSlice("/std.zig.html\" class=\"version-tab");
            if (i == 0) try result.appendSlice(" active");
            try result.appendSlice("\">");
            try result.appendSlice(version);
            try result.appendSlice("</a>\n");
        }
        try result.appendSlice("    </div>\n");

        // Categories grid
        try result.appendSlice("    <div class=\"categories\">\n");
        for (STDLIB_CATEGORIES) |category| {
            try result.appendSlice("        <div class=\"category\">\n");
            try result.appendSlice("            <h3>");
            try result.appendSlice(category.name);
            try result.appendSlice("</h3>\n");
            try result.appendSlice("            <p class=\"category-desc\">");
            try result.appendSlice(category.description);
            try result.appendSlice("</p>\n");
            try result.appendSlice("            <ul class=\"module-list\">\n");

            for (category.modules) |module| {
                try result.appendSlice("                <li class=\"module-item\">\n");
                try result.appendSlice("                    <div class=\"module-name\">");
                try result.appendSlice(module.name);
                try result.appendSlice("</div>\n");
                try result.appendSlice("                    <div class=\"module-desc\">");
                try result.appendSlice(module.description);
                try result.appendSlice("</div>\n");
                try result.appendSlice("                    <div class=\"module-links\">\n");

                // Generate links for each version
                for (versions) |version| {
                    try result.appendSlice("                        <a href=\"");
                    try result.appendSlice(version);
                    try result.appendSlice("/");
                    try result.appendSlice(module.file);
                    try result.appendSlice(".html\" class=\"module-link\">");
                    try result.appendSlice(version);
                    try result.appendSlice("</a>\n");
                }

                try result.appendSlice("                    </div>\n");
                try result.appendSlice("                </li>\n");
            }

            try result.appendSlice("            </ul>\n");
            try result.appendSlice("        </div>\n");
        }
        try result.appendSlice("    </div>\n");

        try result.appendSlice("    <footer style=\"text-align: center; margin: 3em 0; color: #666;\">\n");
        try result.appendSlice("        <p>Generated by <a href=\"https://github.com/paaloeye/zstd-live\">zstd-live</a></p>\n");
        try result.appendSlice("        <p>Inspired by <a href=\"https://web.archive.org/web/20120428101624/http://jashkenas.github.com/docco/\">docco.coffee</a></p>\n");
        try result.appendSlice("    </footer>\n");
        try result.appendSlice("</div>\n");
        try result.appendSlice("</body>\n");
        try result.appendSlice("</html>\n");

        return result.toOwnedSlice();
    }
};

test "template basic functionality" {
    const allocator = std.testing.allocator;
    var template = HtmlTemplate.init(allocator);

    // Test index generation
    const versions = [_][]const u8{ "0.14.1", "0.15.0-master" };
    const index_html = try template.renderIndex(@constCast(&versions));
    defer allocator.free(index_html);

    try std.testing.expect(std.mem.indexOf(u8, index_html, "0.14.1") != null);
    try std.testing.expect(std.mem.indexOf(u8, index_html, "0.15.0-master") != null);
}
