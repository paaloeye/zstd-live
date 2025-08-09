const std = @import("std");

pub const DocComment = struct {
    content: []const u8,
    is_module_doc: bool, // true for //!, false for ///
};

pub const Declaration = struct {
    pub const Type = enum {
        pub_const,
        pub_fn,
        pub_method, // indented pub fn
        test_str, // test "description"
        test_decl, // test identifier
    };

    type: Type,
    name: []const u8,
    line: []const u8,
    import_file: ?[]const u8 = null, // for pub const with @import
};

pub const ParseResult = struct {
    doc_comments: std.ArrayList(DocComment),
    declarations: std.ArrayList(Declaration),
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ParseResult) void {
        // Free doc comment content
        for (self.doc_comments.items) |doc| {
            self.allocator.free(doc.content);
        }
        self.doc_comments.deinit();

        // Free declaration strings
        for (self.declarations.items) |decl| {
            self.allocator.free(decl.name);
            self.allocator.free(decl.line);
            if (decl.import_file) |import_file| {
                self.allocator.free(import_file);
            }
        }
        self.declarations.deinit();
    }
};

pub const ZigParser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ZigParser {
        return ZigParser{ .allocator = allocator };
    }

    pub fn parseFile(self: *ZigParser, content: []const u8) !ParseResult {
        var result = ParseResult{
            .doc_comments = std.ArrayList(DocComment).init(self.allocator),
            .declarations = std.ArrayList(Declaration).init(self.allocator),
            .allocator = self.allocator,
        };

        var lines = std.mem.splitScalar(u8, content, '\n');
        var current_doc: ?std.ArrayList(u8) = null;

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");

            // Handle documentation comments
            if (self.parseDocComment(trimmed)) |doc| {
                if (current_doc == null) {
                    current_doc = std.ArrayList(u8).init(self.allocator);
                }

                if (current_doc.?.items.len > 0) {
                    try current_doc.?.append('\n');
                }
                try current_doc.?.appendSlice(doc.content);

                continue;
            }

            // Try to parse declaration
            if (try self.parseDeclaration(line)) |decl| {
                // If we have accumulated doc comments, add them
                if (current_doc) |*doc_list| {
                    const doc_content = try doc_list.toOwnedSlice();
                    try result.doc_comments.append(DocComment{
                        .content = doc_content,
                        .is_module_doc = false,
                    });
                    current_doc = null;
                }

                try result.declarations.append(decl);
                continue;
            }

            // If we hit non-doc, non-declaration content, finalize any pending docs
            if (current_doc) |*doc_list| {
                const doc_content = try doc_list.toOwnedSlice();
                try result.doc_comments.append(DocComment{
                    .content = doc_content,
                    .is_module_doc = std.mem.startsWith(u8, doc_content, "!"),
                });
                current_doc = null;
            }
        }

        // Cleanup any remaining doc comments
        if (current_doc) |*doc_list| {
            const doc_content = try doc_list.toOwnedSlice();
            try result.doc_comments.append(DocComment{
                .content = doc_content,
                .is_module_doc = std.mem.startsWith(u8, doc_content, "!"),
            });
        }

        return result;
    }

    fn parseDocComment(self: *ZigParser, line: []const u8) ?DocComment {
        _ = self;

        if (std.mem.startsWith(u8, line, "///")) {
            const content = std.mem.trimLeft(u8, line[3..], " ");
            return DocComment{
                .content = content,
                .is_module_doc = false,
            };
        }

        if (std.mem.startsWith(u8, line, "//!")) {
            const content = std.mem.trimLeft(u8, line[3..], " ");
            return DocComment{
                .content = content,
                .is_module_doc = true,
            };
        }

        return null;
    }

    fn parseDeclaration(self: *ZigParser, line: []const u8) !?Declaration {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // pub const
        if (std.mem.startsWith(u8, trimmed, "pub const ")) {
            if (self.extractName(trimmed, "pub const ")) |name| {
                var decl = Declaration{
                    .type = .pub_const,
                    .name = try self.allocator.dupe(u8, name),
                    .line = try self.allocator.dupe(u8, line),
                };

                // Check for @import
                if (std.mem.indexOf(u8, line, "@import(\"")) |start| {
                    const import_start = start + 9; // length of "@import(\""
                    if (std.mem.indexOfScalar(u8, line[import_start..], '"')) |end| {
                        const import_file = line[import_start .. import_start + end];
                        decl.import_file = try self.allocator.dupe(u8, import_file);
                    }
                }

                return decl;
            }
        }

        // pub fn (top-level)
        if (std.mem.startsWith(u8, trimmed, "pub fn ") or std.mem.startsWith(u8, trimmed, "pub inline fn ")) {
            const prefix = if (std.mem.startsWith(u8, trimmed, "pub inline fn ")) "pub inline fn " else "pub fn ";
            if (self.extractName(trimmed, prefix)) |name| {
                return Declaration{
                    .type = .pub_fn,
                    .name = try self.allocator.dupe(u8, name),
                    .line = try self.allocator.dupe(u8, line),
                };
            }
        }

        // pub fn (method - indented)
        if (std.mem.startsWith(u8, line, "    pub fn ") or std.mem.startsWith(u8, line, "    pub inline fn ")) {
            const prefix = if (std.mem.startsWith(u8, line, "    pub inline fn ")) "    pub inline fn " else "    pub fn ";
            if (self.extractName(line, prefix)) |name| {
                return Declaration{
                    .type = .pub_method,
                    .name = try self.allocator.dupe(u8, name),
                    .line = try self.allocator.dupe(u8, line),
                };
            }
        }

        // test "string"
        if (std.mem.indexOf(u8, trimmed, "test \"")) |start| {
            const test_start = start + 6; // length of "test \""
            if (std.mem.indexOfScalar(u8, trimmed[test_start..], '"')) |end| {
                const test_name = trimmed[test_start .. test_start + end];
                return Declaration{
                    .type = .test_str,
                    .name = try self.allocator.dupe(u8, test_name),
                    .line = try self.allocator.dupe(u8, line),
                };
            }
        }

        // test identifier
        if (std.mem.startsWith(u8, trimmed, "test ")) {
            if (self.extractTestIdentifier(trimmed)) |name| {
                return Declaration{
                    .type = .test_decl,
                    .name = try self.allocator.dupe(u8, name),
                    .line = try self.allocator.dupe(u8, line),
                };
            }
        }

        return null;
    }

    fn extractName(self: *ZigParser, line: []const u8, prefix: []const u8) ?[]const u8 {
        _ = self;

        if (!std.mem.startsWith(u8, line, prefix)) return null;

        const after_prefix = line[prefix.len..];
        const end_idx = std.mem.indexOfAny(u8, after_prefix, " (=") orelse after_prefix.len;

        if (end_idx == 0) return null;
        return after_prefix[0..end_idx];
    }

    fn extractTestIdentifier(self: *ZigParser, line: []const u8) ?[]const u8 {
        _ = self;

        if (!std.mem.startsWith(u8, line, "test ")) return null;

        const after_test = std.mem.trimLeft(u8, line[5..], " ");

        // Skip if it starts with a quote (already handled by test_str)
        if (std.mem.startsWith(u8, after_test, "\"")) return null;

        const end_idx = std.mem.indexOfAny(u8, after_test, " {") orelse after_test.len;

        if (end_idx == 0) return null;
        return after_test[0..end_idx];
    }

    pub fn processInlineCode(self: *ZigParser, text: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        var i: usize = 0;

        while (i < text.len) {
            if (text[i] == '`' and i + 1 < text.len) {
                // Find closing backtick
                if (std.mem.indexOfScalar(u8, text[i + 1 ..], '`')) |end| {
                    const code_content = text[i + 1 .. i + 1 + end];
                    try result.appendSlice("<code>");
                    try result.appendSlice(code_content);
                    try result.appendSlice("</code>");
                    i = i + 2 + end;
                    continue;
                }
            }
            try result.append(text[i]);
            i += 1;
        }

        return result.toOwnedSlice();
    }
};

test "parser basic functionality" {
    const allocator = std.testing.allocator;
    var parser = ZigParser.init(allocator);

    const sample_code =
        \\/// This is a documentation comment
        \\/// for a public constant
        \\pub const example = @import("example.zig");
        \\
        \\/// Function documentation
        \\pub fn testFunction() void {}
        \\
        \\    /// Method documentation
        \\    pub fn methodFunction(self: *Self) void {}
        \\
        \\test "string test" {}
        \\
        \\test identifier_test {}
    ;

    var result = try parser.parseFile(sample_code);
    defer result.deinit();

    // Should find declarations
    try std.testing.expect(result.declarations.items.len >= 3);

    // Test inline code processing
    const processed = try parser.processInlineCode("This has `inline code` in it");
    defer allocator.free(processed);
    try std.testing.expect(std.mem.indexOf(u8, processed, "<code>inline code</code>") != null);
}
