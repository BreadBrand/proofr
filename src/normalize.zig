const std = @import("std");
const types = @import("./types.zig");

pub fn normalize(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    if (input.len == 0) {
        return types.ParseError.InputEmpty;
    }

    if (try std.unicode.utf8CountCodepoints(input) > 10000) {
        return types.ParseError.InputTooLarge;
    }

    const noHtml = try stripHtml(allocator, input);
    const escaped_entities = try unescapedEntities(allocator, noHtml);
    const noMarkdown = try stripMarkdown(allocator, escaped_entities);
    const replaceUnicode = try convertUnicode(allocator, noMarkdown);
    const floatingMixedNumbers = try convertMixedNumbers(allocator, replaceUnicode);

    const normalized = floatingMixedNumbers;

    return normalized;
}

fn stripHtml(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var skip = false;
    var html_stripped: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (input[i] == '<') {
            skip = true;
        }
        if (input[i] == '>') {
            skip = false;
            continue;
        }
        if (skip) {
            continue;
        } else {
            try html_stripped.append(allocator, input[i]);
        }
    }
    return try html_stripped.toOwnedSlice(allocator);
}

fn unescapedEntities(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var escaping = false;
    var unescaped: [20]u8 = undefined;
    var unescaped_len: usize = 0;
    var escaped_chars: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        // see '&' → enter entity mode, start collecting
        // see '&' while already in entity mode → flush raw bytes to output, start fresh
        if (escaping and input[i] == '&') {
            try escaped_chars.append(allocator, input[i]);
            try escaped_chars.appendSlice(allocator, unescaped[0..unescaped_len]);
            unescaped = undefined;
            unescaped_len = 0;
            continue;
        }
        if (escaping and input[i] == ';') {
            // see ';' → resolve collected bytes, exit entity mode
            if (unescapeChar(unescaped[0..unescaped_len])) |replacement| {
                try escaped_chars.appendSlice(allocator, replacement);
            } else {
                try escaped_chars.append(allocator, '&');
                try escaped_chars.appendSlice(allocator, unescaped[0..unescaped_len]);
                try escaped_chars.append(allocator, ';');
            }
            escaping = false;
            unescaped_len = 0;
            unescaped = undefined;
            continue;
        }
        if (input[i] == '&') {
            escaping = true;
            continue;
        }
        if (escaping) {
            unescaped[unescaped_len] = input[i];
            unescaped_len += 1;
        } else {
            try escaped_chars.append(allocator, input[i]);
        }

        // see end of input while in entity mode → flush raw bytes as-is
        // otherwise → if in entity mode, append to collection buffer if not in entity mode, append to output
    }
    if (escaping) {
        try escaped_chars.append(allocator, '&');
        try escaped_chars.appendSlice(allocator, unescaped[0..unescaped_len]);
    }
    return try escaped_chars.toOwnedSlice(allocator);
}

fn unescapeChar(char: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, char, "nbsp")) return " ";
    if (std.mem.eql(u8, char, "amp")) return "&";
    if (std.mem.eql(u8, char, "lt")) return "<";
    if (std.mem.eql(u8, char, "gt")) return ">";
    if (std.mem.eql(u8, char, "quot")) return "\"";
    if (std.mem.eql(u8, char, "apos")) return "'";
    if (std.mem.eql(u8, char, "frac12")) return "1/2";
    if (std.mem.eql(u8, char, "frac14")) return "1/4";
    if (std.mem.eql(u8, char, "frac34")) return "3/4";
    if (std.mem.eql(u8, char, "frac13")) return "1/3";
    if (std.mem.eql(u8, char, "frac23")) return "2/3";
    return null;
}

fn stripMarkdown(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var markdown_stripped: std.ArrayList(u8) = .empty;
    errdefer markdown_stripped.deinit(allocator);
    while (lines.next()) |line| {
        const no_headers = try stripHeadingMarks(allocator, line);
        defer allocator.free(no_headers);
        const no_stars = try stripBoldAndItalicMarkers(allocator, no_headers);
        defer allocator.free(no_stars);
        const no_links = try stripInlineLinks(allocator, no_stars);
        defer allocator.free(no_links);
        try markdown_stripped.appendSlice(allocator, no_links);
    }

    return try markdown_stripped.toOwnedSlice(allocator);
}

fn stripHeadingMarks(allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
    var no_headers: std.ArrayList(u8) = .empty;
    errdefer no_headers.deinit(allocator);
    var i: usize = 0;
    if (line.len > 0 and line[0] == '#') {
        while (i < line.len and line[i] == '#') : (i += 1) {}
        if (i < line.len and line[i] == ' ') i += 1;
    }
    try no_headers.appendSlice(allocator, line[i..]);
    try no_headers.append(allocator, '\n');

    return try no_headers.toOwnedSlice(allocator);
}

fn stripBoldAndItalicMarkers(allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
    var no_stars: std.ArrayList(u8) = .empty;
    errdefer no_stars.deinit(allocator);
    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == '*') {
            const start = i;
            while (i < line.len and line[i] == '*') : (i += 1) {}
            const prev: u8 = if (start > 0) line[start - 1] else ' ';
            const next: u8 = if (i < line.len) line[i] else ' ';
            if (prev == ' ' and next == ' ') {
                try no_stars.appendSlice(allocator, line[start..i]);
            }
        } else {
            try no_stars.append(allocator, line[i]);
            i += 1;
        }
    }
    return try no_stars.toOwnedSlice(allocator);
}

fn stripInlineLinks(allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
    var no_inline_url: std.ArrayList(u8) = .empty;
    errdefer no_inline_url.deinit(allocator);
    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == '[') {
            i += 1;
            const start = i;
            while (i < line.len and line[i] != ']') : (i += 1) {}
            const text = line[start..i];
            i += 1;
            if (i < line.len and line[i] == '(') {
                try no_inline_url.appendSlice(allocator, text);
                while (i < line.len and line[i] != ')') : (i += 1) {}
                i += 1;
            } else {
                try no_inline_url.append(allocator, '[');
                try no_inline_url.appendSlice(allocator, text);
            }
        } else {
            try no_inline_url.append(allocator, line[i]);
            i += 1;
        }
    }
    return try no_inline_url.toOwnedSlice(allocator);
}

fn convertUnicode(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const view = try std.unicode.Utf8View.init(input);
    var it = view.iterator();
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);

    while (true) {
        const start = it.i;
        const cp = it.nextCodepoint() orelse break;
        switch (cp) {
            '\u{2018}', '\u{2019}' => try output.append(allocator, '\''),
            '\u{201C}', '\u{201D}' => try output.append(allocator, '"'),
            '\u{2013}', '\u{2014}' => try output.append(allocator, '-'),
            '½' => try output.appendSlice(allocator, "1/2"),
            '¼' => try output.appendSlice(allocator, "1/4"),
            '¾' => try output.appendSlice(allocator, "3/4"),
            '⅓' => try output.appendSlice(allocator, "1/3"),
            '⅔' => try output.appendSlice(allocator, "2/3"),
            '⅛' => try output.appendSlice(allocator, "1/8"),
            else => try output.appendSlice(allocator, it.bytes[start..it.i]),
        }
    }
    return try output.toOwnedSlice(allocator);
}

fn convertMixedNumbers(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var output: std.ArrayList(u8) = .empty;
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        const expanded = try expandMixedNumbersInLine(allocator, line);
        defer allocator.free(expanded);
        try output.appendSlice(allocator, expanded);
        try output.append(allocator, '\n');
    }

    return try output.toOwnedSlice(allocator);
}

fn expandMixedNumbersInLine(allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var i: usize = 0;

    while (i < line.len) {
        if (std.ascii.isDigit(line[i])) {
            const int_start = i;
            while (i < line.len and std.ascii.isDigit(line[i])) : (i += 1) {}
            const int_end = i;

            //check for space then digit
            if (i < line.len and
                line[i] == ' ' and
                i + 1 < line.len and
                std.ascii.isDigit(line[i + 1]))
            {
                //look for slash and number
                const num_start = i + 1;
                var j = num_start;
                while (j < line.len and std.ascii.isDigit(line[j])) : (j += 1) {}

                if (j < line.len and line[j] == '/' and
                    j + 1 < line.len and
                    std.ascii.isDigit(line[j + 1]))
                {
                    const den_start = j + 1;
                    var k = den_start;
                    while (k < line.len and std.ascii.isDigit(line[k])) : (k += 1) {}

                    const whole = try std.fmt.parseInt(u32, line[int_start..int_end], 10);
                    const num = try std.fmt.parseInt(u32, line[num_start..j], 10);
                    const den = try std.fmt.parseInt(u32, line[den_start..k], 10);

                    if (den != 0) {
                        const value: f64 = @as(f64, @floatFromInt(whole)) + @as(f64, @floatFromInt(num)) / @as(f64, @floatFromInt(den));
                        var buf: [32]u8 = undefined;
                        const formatted = try std.fmt.bufPrint(&buf, "{d:.2}", .{value});
                        const trimmed = trimTrailingZeros(formatted);
                        try output.appendSlice(allocator, trimmed);
                        i = k;
                        continue;
                    }
                }
            }

            try output.appendSlice(allocator, line[int_start..int_end]);
        } else {
            try output.append(allocator, line[i]);
            i += 1;
        }
    }
    return try output.toOwnedSlice(allocator);
}

fn trimTrailingZeros(s: []const u8) []const u8 {
    var end = s.len;
    while (end > 0 and s[end - 1] == 0) : (end -= 1) {}
    if (end > 0 and s[end - 1] == '.') end -= 1;
    return s[0..end];
}

test "strip heading markdown" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripMarkdown(allocator, "## Instructions");
    try std.testing.expectEqualStrings("Instructions\n", result);
}

test "strip bold" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripBoldAndItalicMarkers(allocator, "**500g** flour");
    try std.testing.expectEqualStrings("500g flour", result);
}

test "strip inline link" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripInlineLinks(allocator, "[click here](http://x.com)");
    try std.testing.expectEqualStrings("click here", result);
}

test "smart quote left single" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try convertUnicode(allocator, "\u{2018}active\u{2019}");
    try std.testing.expectEqualStrings("'active'", result);
}

test "unicode fraction half" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try convertUnicode(allocator, "½ cup");
    try std.testing.expectEqualStrings("1/2 cup", result);
}

test "mixed number" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try convertMixedNumbers(allocator, "2 3/4 cups Strong Bread Flour");
    try std.testing.expectEqualStrings("2.75 cups Strong Bread Flour\n", result);
}

test "stripHtml basic tag" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripHtml(allocator, "<b>hello</b>");
    try std.testing.expectEqualStrings("hello", result);
}

test "stripHtml unclosed tag" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripHtml(allocator, "<b>hello");
    try std.testing.expectEqualStrings("hello", result);
}

test "stripHtml nested < inside tag" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripHtml(allocator, "<div class=\"a<b\">hello</div>");
    try std.testing.expectEqualStrings("hello", result);
}

test "stripHtml no tags at all" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try stripHtml(allocator, "hello");
    try std.testing.expectEqualStrings("hello", result);
}

test "unescapedEntities known entity &nbsp;" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try unescapedEntities(allocator, "hello&nbsp;world");
    try std.testing.expectEqualStrings("hello world", result);
}

test "unescapedEntities unknown entity &foo; -> &foo;" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try unescapedEntities(allocator, "hello&foo;world");
    try std.testing.expectEqualStrings("hello&foo;world", result);
}

test "unescapedEntites m&m with no semicolon -> m&m" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try unescapedEntities(allocator, "hello m&m's");
    try std.testing.expectEqualStrings("hello m&m's", result);
}

test "unescapedEntities multiple entities in one string" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try unescapedEntities(allocator, "hello&lt;world&nbsp;&frac12;&nbsp;&amp;&nbsp;&frac34;");
    try std.testing.expectEqualStrings("hello<world 1/2 & 3/4", result);
}

test "normalize empty input" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try std.testing.expectError(types.ParseError.InputEmpty, normalize(allocator, ""));
}

test "normalize oversized input" {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const big_input = "a" ** 10001;

    try std.testing.expectError(types.ParseError.InputTooLarge, normalize(allocator, big_input));
}
