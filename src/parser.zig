const std = @import("std");
const types = @import("./types.zig");

pub fn parse(allocator: std.mem.Allocator, input: []const u8) !types.ParseResult {
    _ = allocator;
    _ = input;

    return types.ParseResult{
        .title = "",
        .description = "",
        .yeast_type = "",
        .ingredients = &.{},
        .instructions = &.{},
        .confidence = types.ConfidenceMeta{
            .title = types.SectionConfidence{
                .score = 0.0,
                .flags = &.{},
            },
            .ingredients = types.SectionConfidence{
                .score = 0.0,
                .flags = &.{},
            },
            .instructions = types.SectionConfidence{
                .score = 0.0,
                .flags = &.{},
            },
        },
        .parse_errors = &.{},
        .metadata = null
    };
}
