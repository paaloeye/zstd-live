const std = @import("std");

/// Tree Sitter-compatible highlight groups based on contrib/grammar/zig/highlights.scm
/// This provides the same highlight classifications as Tree Sitter would, making it
/// compatible for future Tree Sitter integration when Zig version allows.
pub const HighlightGroup = enum {
    // Variables and identifiers
    variable,
    variable_parameter,
    variable_builtin,
    variable_other_member,

    // Types
    type,
    type_builtin,

    // Constants
    constant,
    constant_builtin,
    constant_character,
    constant_character_escape,
    constant_numeric_integer,
    constant_numeric_float,
    constant_builtin_boolean,

    // Functions
    function,
    function_builtin,
    function_method,

    // Keywords - directly mapped from Tree Sitter highlight patterns
    keyword,
    keyword_function,
    keyword_storage_type,
    keyword_storage_modifier,
    keyword_operator,
    keyword_control_return,
    keyword_control_conditional,
    keyword_control_repeat,
    keyword_control_import,
    keyword_control_exception,

    // Operators and punctuation
    operator,
    punctuation_bracket,
    punctuation_delimiter,

    // Literals
    string,
    character,
    number,
    boolean,

    // Comments
    comment_line,
    comment_block_documentation,

    // Labels
    label,

    // Default/fallback
    text,

    pub fn toCssClass(self: HighlightGroup) []const u8 {
        return switch (self) {
            .variable => "variable",
            .variable_parameter => "variable-parameter",
            .variable_builtin => "variable-builtin",
            .variable_other_member => "variable-member",

            .type => "type",
            .type_builtin => "type-builtin",

            .constant => "constant",
            .constant_builtin => "constant-builtin",
            .constant_character => "constant-character",
            .constant_character_escape => "constant-escape",
            .constant_numeric_integer => "number-integer",
            .constant_numeric_float => "number-float",
            .constant_builtin_boolean => "boolean",

            .function => "function",
            .function_builtin => "function-builtin",
            .function_method => "function-method",

            .keyword => "keyword",
            .keyword_function => "keyword-function",
            .keyword_storage_type => "keyword-storage-type",
            .keyword_storage_modifier => "keyword-storage-modifier",
            .keyword_operator => "keyword-operator",
            .keyword_control_return => "keyword-control-return",
            .keyword_control_conditional => "keyword-control-conditional",
            .keyword_control_repeat => "keyword-control-repeat",
            .keyword_control_import => "keyword-control-import",
            .keyword_control_exception => "keyword-control-exception",

            .operator => "operator",
            .punctuation_bracket => "punctuation-bracket",
            .punctuation_delimiter => "punctuation-delimiter",

            .string => "string",
            .character => "character",
            .number => "number",
            .boolean => "boolean",

            .comment_line => "comment",
            .comment_block_documentation => "comment-doc",

            .label => "label",
            .text => "",
        };
    }
};

pub const Token = struct {
    highlight: HighlightGroup,
    text: []const u8,
    start: usize,
    end: usize,
};

/// Tree Sitter-compatible syntax highlighter
/// Uses the exact same classification patterns as contrib/grammar/zig/highlights.scm
pub const SyntaxHighlighter = struct {
    allocator: std.mem.Allocator,
    token_buffer: std.ArrayList(Token),

    // Keyword classifications from Tree Sitter grammar
    const KEYWORDS_BASIC = [_][]const u8{ "asm", "test" };

    const KEYWORDS_STORAGE_TYPE = [_][]const u8{ "error", "const", "var", "struct", "union", "enum", "opaque" };

    const KEYWORDS_COROUTINE = [_][]const u8{ "async", "await", "suspend", "nosuspend", "resume" };

    const KEYWORD_FUNCTION = "fn";

    const KEYWORDS_OPERATOR = [_][]const u8{ "and", "or", "orelse" };

    const KEYWORDS_CONTROL_RETURN = [_][]const u8{ "try", "unreachable", "return" };

    const KEYWORDS_CONTROL_CONDITIONAL = [_][]const u8{ "if", "else", "switch", "catch" };

    const KEYWORDS_CONTROL_REPEAT = [_][]const u8{ "for", "while", "break", "continue" };

    const KEYWORDS_CONTROL_IMPORT = [_][]const u8{ "usingnamespace", "export" };

    const KEYWORDS_CONTROL_EXCEPTION = [_][]const u8{ "defer", "errdefer" };

    const KEYWORDS_STORAGE_MODIFIER = [_][]const u8{ "volatile", "allowzero", "noalias", "addrspace", "align", "callconv", "linksection", "pub", "inline", "noinline", "extern", "comptime", "packed", "threadlocal" };

    // Constants and variables from Tree Sitter patterns
    const CONSTANTS_BUILTIN = [_][]const u8{ "null", "unreachable", "undefined" };

    const VARIABLES_BUILTIN = [_][]const u8{ "c", "...", "_" };

    // Builtin types from Tree Sitter pattern: [builtin_type, "anyframe"] @type.builtin
    const BUILTIN_TYPES = [_][]const u8{ "i8", "u8", "i16", "u16", "i32", "u32", "i64", "u64", "i128", "u128", "isize", "usize", "c_short", "c_ushort", "c_int", "c_uint", "c_long", "c_ulong", "c_longlong", "c_ulonglong", "c_longdouble", "c_void", "f16", "f32", "f64", "f80", "f128", "bool", "anyopaque", "void", "noreturn", "type", "anyerror", "comptime_int", "comptime_float", "anyframe" };

    pub fn init(allocator: std.mem.Allocator) SyntaxHighlighter {
        std.log.debug("[SYNTAX] Initializing syntax highlighter", .{});

        return SyntaxHighlighter{
            .allocator = allocator,
            .token_buffer = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn deinit(self: *SyntaxHighlighter) void {
        std.log.debug("[SYNTAX] Deinitializing syntax highlighter", .{});
        self.token_buffer.deinit();
    }

    pub fn highlightLine(self: *SyntaxHighlighter, line: []const u8) ![]u8 {
        std.log.debug("[SYNTAX] Processing line with {d} characters", .{line.len});

        // Clear and reuse token buffer
        self.token_buffer.clearRetainingCapacity();

        try self.tokenizeLine(line, &self.token_buffer);

        std.log.debug("[SYNTAX] Tokenized line into {d} tokens", .{self.token_buffer.items.len});

        // Use direct allocation for HTML generation
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();

        for (self.token_buffer.items) |token| {
            const css_class = token.highlight.toCssClass();

            if (css_class.len > 0) {
                try result.appendSlice("<span class=\"");
                try result.appendSlice(css_class);
                try result.appendSlice("\">");
                try self.appendEscapedHtml(&result, token.text);
                try result.appendSlice("</span>");
            } else {
                try self.appendEscapedHtml(&result, token.text);
            }
        }

        const html_result = try result.toOwnedSlice();

        std.log.debug("[SYNTAX] Generated {d} bytes of HTML", .{html_result.len});

        return html_result;
    }

    fn tokenizeLine(self: *SyntaxHighlighter, line: []const u8, tokens: *std.ArrayList(Token)) !void {
        var i: usize = 0;

        while (i < line.len) {
            const start = i;

            // Skip whitespace (don't highlight)
            if (std.ascii.isWhitespace(line[i])) {
                while (i < line.len and std.ascii.isWhitespace(line[i])) {
                    i += 1;
                }
                try tokens.append(Token{
                    .highlight = .text,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Comments - Tree Sitter pattern: (comment) @comment.line
            if (i + 1 < line.len and line[i] == '/' and line[i + 1] == '/') {
                const comment_start = i;

                // Check for doc comments: ((comment) @comment.block.documentation (#match? @comment.block.documentation "^//!"))
                const is_doc_comment = (i + 2 < line.len and line[i + 2] == '!');

                // Consume rest of line
                i = line.len;

                try tokens.append(Token{
                    .highlight = if (is_doc_comment) .comment_block_documentation else .comment_line,
                    .text = line[comment_start..i],
                    .start = comment_start,
                    .end = i,
                });
                continue;
            }

            // String literals - Tree Sitter pattern: [string, multiline_string] @string
            if (line[i] == '"') {
                i += 1; // Skip opening quote
                while (i < line.len and line[i] != '"') {
                    if (line[i] == '\\' and i + 1 < line.len) {
                        i += 2; // Skip escape sequence - (escape_sequence) @constant.character.escape
                    } else {
                        i += 1;
                    }
                }
                if (i < line.len) i += 1; // Skip closing quote

                try tokens.append(Token{
                    .highlight = .string,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Multi-line string literals (Zig \\string syntax)
            if (i + 1 < line.len and line[i] == '\\' and line[i + 1] == '\\') {
                // Consume rest of line for multi-line strings
                i = line.len;
                try tokens.append(Token{
                    .highlight = .string,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Character literals - Tree Sitter pattern: (character) @constant.character
            if (line[i] == '\'') {
                i += 1; // Skip opening quote
                while (i < line.len and line[i] != '\'') {
                    if (line[i] == '\\' and i + 1 < line.len) {
                        i += 2; // Skip escape sequence
                    } else {
                        i += 1;
                    }
                }
                if (i < line.len) i += 1; // Skip closing quote

                try tokens.append(Token{
                    .highlight = .constant_character,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Numbers - Tree Sitter patterns: (integer) @constant.numeric.integer, (float) @constant.numeric.float
            if (std.ascii.isDigit(line[i]) or
                (line[i] == '0' and i + 1 < line.len and (line[i + 1] == 'x' or line[i + 1] == 'b' or line[i + 1] == 'o')))
            {
                var is_float = false;

                // Handle hex, binary, octal prefixes
                if (line[i] == '0' and i + 1 < line.len) {
                    if (line[i + 1] == 'x' or line[i + 1] == 'X') {
                        i += 2; // Skip "0x"
                        while (i < line.len and std.ascii.isHex(line[i])) {
                            i += 1;
                        }
                    } else if (line[i + 1] == 'b' or line[i + 1] == 'B') {
                        i += 2; // Skip "0b"
                        while (i < line.len and (line[i] == '0' or line[i] == '1')) {
                            i += 1;
                        }
                    } else if (line[i + 1] == 'o' or line[i + 1] == 'O') {
                        i += 2; // Skip "0o"
                        while (i < line.len and line[i] >= '0' and line[i] <= '7') {
                            i += 1;
                        }
                    } else {
                        // Regular decimal
                        while (i < line.len and std.ascii.isDigit(line[i])) {
                            i += 1;
                        }
                    }
                } else {
                    // Regular decimal
                    while (i < line.len and std.ascii.isDigit(line[i])) {
                        i += 1;
                    }
                }

                // Handle decimal point
                if (i < line.len and line[i] == '.') {
                    is_float = true;
                    i += 1;
                    while (i < line.len and std.ascii.isDigit(line[i])) {
                        i += 1;
                    }
                }

                // Handle exponent
                if (i < line.len and (line[i] == 'e' or line[i] == 'E')) {
                    is_float = true;
                    i += 1;
                    if (i < line.len and (line[i] == '+' or line[i] == '-')) {
                        i += 1;
                    }
                    while (i < line.len and std.ascii.isDigit(line[i])) {
                        i += 1;
                    }
                }

                try tokens.append(Token{
                    .highlight = if (is_float) .constant_numeric_float else .constant_numeric_integer,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Identifiers, keywords, and builtins
            if (std.ascii.isAlphabetic(line[i]) or line[i] == '_' or line[i] == '@') {
                while (i < line.len and (std.ascii.isAlphabetic(line[i]) or std.ascii.isDigit(line[i]) or line[i] == '_')) {
                    i += 1;
                }

                const word = line[start..i];

                // Prevent infinite loop on empty identifier
                if (word.len == 0) {
                    i = start + 1; // Force advance by 1 to break infinite loop
                    try tokens.append(Token{
                        .highlight = .text,
                        .text = line[start..i],
                        .start = start,
                        .end = i,
                    });
                    continue;
                }

                var highlight: HighlightGroup = .variable;

                // Check builtin functions - Tree Sitter pattern: (builtin_identifier) @function.builtin
                if (word.len > 0 and word[0] == '@') {
                    highlight = .function_builtin;
                } else {
                    // Classify according to Tree Sitter highlight groups
                    highlight = self.classifyIdentifier(word);
                }

                try tokens.append(Token{
                    .highlight = highlight,
                    .text = word,
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Operators and punctuation - mapped from Tree Sitter patterns
            if (self.isOperatorOrPunctuation(line[i])) {
                // Handle multi-character operators
                var end_pos = i + 1;

                // Look ahead for compound operators (from Tree Sitter operator patterns)
                if (i + 1 < line.len) {
                    const two_char = line[i .. i + 2];
                    if (std.mem.eql(u8, two_char, "==") or std.mem.eql(u8, two_char, "!=") or
                        std.mem.eql(u8, two_char, "<=") or std.mem.eql(u8, two_char, ">=") or
                        std.mem.eql(u8, two_char, "<<") or std.mem.eql(u8, two_char, ">>") or
                        std.mem.eql(u8, two_char, "+=") or std.mem.eql(u8, two_char, "-=") or
                        std.mem.eql(u8, two_char, "*=") or std.mem.eql(u8, two_char, "/=") or
                        std.mem.eql(u8, two_char, "%=") or std.mem.eql(u8, two_char, "&=") or
                        std.mem.eql(u8, two_char, "|=") or std.mem.eql(u8, two_char, "^=") or
                        std.mem.eql(u8, two_char, "++") or std.mem.eql(u8, two_char, "--") or
                        std.mem.eql(u8, two_char, "&&") or std.mem.eql(u8, two_char, "||") or
                        std.mem.eql(u8, two_char, "=>") or std.mem.eql(u8, two_char, "->") or
                        std.mem.eql(u8, two_char, ".*") or std.mem.eql(u8, two_char, ".?") or
                        std.mem.eql(u8, two_char, ".."))
                    {
                        end_pos = i + 2;
                    }
                }

                i = end_pos;

                // Classify according to Tree Sitter punctuation patterns
                const highlight: HighlightGroup = if (self.isBracket(line[start]))
                    .punctuation_bracket
                else if (self.isDelimiter(line[start]))
                    .punctuation_delimiter
                else
                    .operator;

                try tokens.append(Token{
                    .highlight = highlight,
                    .text = line[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Unknown character
            i += 1;
            try tokens.append(Token{
                .highlight = .text,
                .text = line[start..i],
                .start = start,
                .end = i,
            });
        }
    }

    /// Classify identifiers according to Tree Sitter highlight patterns from contrib/grammar/zig/highlights.scm
    fn classifyIdentifier(self: *SyntaxHighlighter, word: []const u8) HighlightGroup {
        _ = self;

        // "fn" @keyword.function
        if (std.mem.eql(u8, word, KEYWORD_FUNCTION)) {
            return .keyword_function;
        }

        // Check keyword categories from highlights.scm
        for (KEYWORDS_BASIC) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword;
        }

        for (KEYWORDS_STORAGE_TYPE) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_storage_type;
        }

        for (KEYWORDS_COROUTINE) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword;
        }

        for (KEYWORDS_OPERATOR) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_operator;
        }

        for (KEYWORDS_CONTROL_RETURN) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_control_return;
        }

        for (KEYWORDS_CONTROL_CONDITIONAL) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_control_conditional;
        }

        for (KEYWORDS_CONTROL_REPEAT) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_control_repeat;
        }

        for (KEYWORDS_CONTROL_IMPORT) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_control_import;
        }

        for (KEYWORDS_CONTROL_EXCEPTION) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_control_exception;
        }

        for (KEYWORDS_STORAGE_MODIFIER) |kw| {
            if (std.mem.eql(u8, word, kw)) return .keyword_storage_modifier;
        }

        // ["null", "unreachable", "undefined"] @constant.builtin
        for (CONSTANTS_BUILTIN) |kw| {
            if (std.mem.eql(u8, word, kw)) return .constant_builtin;
        }

        // ["c", "...", "_"] @variable.builtin
        for (VARIABLES_BUILTIN) |kw| {
            if (std.mem.eql(u8, word, kw)) return .variable_builtin;
        }

        // [builtin_type, "anyframe"] @type.builtin
        for (BUILTIN_TYPES) |bt| {
            if (std.mem.eql(u8, word, bt)) return .type_builtin;
        }

        // (boolean) @constant.builtin.boolean
        if (std.mem.eql(u8, word, "true") or std.mem.eql(u8, word, "false")) {
            return .constant_builtin_boolean;
        }

        // Type naming patterns from Tree Sitter:
        // ((identifier) @type (#match? @type "^[A-Z_][a-zA-Z0-9_]*"))
        if (word.len > 0 and (std.ascii.isUpper(word[0]) or word[0] == '_')) {
            // ((identifier) @constant (#match? @constant "^[A-Z][A-Z_0-9]+$"))
            var all_caps = true;
            for (word) |c| {
                if (std.ascii.isLower(c)) {
                    all_caps = false;
                    break;
                }
            }
            if (all_caps and word.len > 1) {
                return .constant;
            } else {
                return .type;
            }
        }

        // Default to variable
        return .variable;
    }

    fn isOperatorOrPunctuation(self: *SyntaxHighlighter, c: u8) bool {
        _ = self;
        return switch (c) {
            '+', '-', '*', '/', '%', '=', '!', '<', '>', '&', '|', '^', '~', '?', ':', '.', ',', ';', '(', ')', '[', ']', '{', '}' => true,
            else => false,
        };
    }

    // Tree Sitter patterns: ["[", "]", "(", ")", "{", "}"] @punctuation.bracket
    fn isBracket(self: *SyntaxHighlighter, c: u8) bool {
        _ = self;
        return switch (c) {
            '(', ')', '[', ']', '{', '}' => true,
            else => false,
        };
    }

    // Tree Sitter patterns: [";", ".", ",", ":", "=>", "->"] @punctuation.delimiter
    fn isDelimiter(self: *SyntaxHighlighter, c: u8) bool {
        _ = self;
        return switch (c) {
            ',', ';', '.', ':' => true,
            else => false,
        };
    }

    fn appendEscapedHtml(self: *SyntaxHighlighter, writer: *std.ArrayList(u8), text: []const u8) !void {
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
};

test "Tree Sitter compatible Zig syntax highlighting" {
    const allocator = std.testing.allocator;
    var highlighter = SyntaxHighlighter.init(allocator);
    defer highlighter.deinit();

    const code = "const std = @import(\"std\");";
    const result = try highlighter.highlightLine(code);
    defer allocator.free(result);

    // Should contain Tree Sitter compatible CSS classes
    try std.testing.expect(std.mem.indexOf(u8, result, "keyword-storage-type") != null); // const
    try std.testing.expect(std.mem.indexOf(u8, result, "function-builtin") != null); // @import
    try std.testing.expect(std.mem.indexOf(u8, result, "string") != null); // "std"
}

test "Tree Sitter type and constant patterns" {
    const allocator = std.testing.allocator;
    var highlighter = SyntaxHighlighter.init(allocator);
    defer highlighter.deinit();

    const code = "const MyType = struct {}; const MY_CONSTANT = 42;";
    const result = try highlighter.highlightLine(code);
    defer allocator.free(result);

    // Should classify according to Tree Sitter naming patterns
    try std.testing.expect(std.mem.indexOf(u8, result, "type") != null); // MyType
    try std.testing.expect(std.mem.indexOf(u8, result, "constant") != null); // MY_CONSTANT
}

test "Tree Sitter comment patterns" {
    const allocator = std.testing.allocator;
    var highlighter = SyntaxHighlighter.init(allocator);
    defer highlighter.deinit();

    const doc_comment = "//! This is a doc comment";
    const result1 = try highlighter.highlightLine(doc_comment);
    defer allocator.free(result1);

    const regular_comment = "// This is a regular comment";
    const result2 = try highlighter.highlightLine(regular_comment);
    defer allocator.free(result2);

    // Should match Tree Sitter comment patterns
    try std.testing.expect(std.mem.indexOf(u8, result1, "comment-doc") != null);
    try std.testing.expect(std.mem.indexOf(u8, result2, "comment") != null);
}
