const std = @import("std");
const types = @import("./types.zig");

pub fn normalize(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    if (input.len == 0) {
        return types.ParseError.InputEmpty;
    }

    if (try std.unicode.utf8CountCodepoints(input) > 10000) {
        return types.ParseError.InputTooLarge;
    }

    const normalized = try stripHtml(allocator, input);
    const escaped_entities = try unescapedEntities(allocator, normalized);

    return escaped_entities;
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
