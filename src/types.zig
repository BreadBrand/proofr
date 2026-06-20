const std = @import("std");

pub const ParseError = error{
    InputEmpty,
    InputTooLarge,
};

pub const Ingredient = struct {
    name: []const u8,
    quantity: []const u8,
    unit: []const u8,
    phase: []const u8,
    raw_line: []const u8,
    confidence: f32,
};

pub const InstructionStep = struct {
    step: []const u8,
    confidence: f32,
};

pub const Nutrition = struct {
    calories: ?[]const u8 = null,
    total_fat: ?[]const u8 = null,
    saturated_fat: ?[]const u8 = null,
    trans_fat: ?[]const u8 = null,
    cholesterol: ?[]const u8 = null,
    sodium: ?[]const u8 = null,
    total_carbohydrates: ?[]const u8 = null,
    dietary_fiber: ?[]const u8 = null,
    sugars: ?[]const u8 = null,
    protein: ?[]const u8 = null,
};

pub const Metadata = struct {
    prep_time: ?u32 = null,
    cook_time: ?u32 = null,
    additional_time: ?u32 = null,
    servings: ?[]const u8 = null,
    notes: [][]const u8 = &.{},
    nutrition: ?Nutrition = null,
};

pub const SectionConfidence = struct {
    score: f32,
    flags: [][]const u8 = &.{},
};

pub const ConfidenceMeta = struct {
    title: SectionConfidence,
    ingredients: SectionConfidence,
    instructions: SectionConfidence,
};

pub const ParseResult = struct {
    title: []const u8,
    description: []const u8,
    yeast_type: []const u8, // "dry", "sourdough", or "none"
    ingredients: []Ingredient,
    instructions: []InstructionStep,
    metadata: ?Metadata,
    confidence: ConfidenceMeta,
    parse_errors: [][]const u8,
};

test "types compile" {
    const i = Ingredient{
        .name = "flour", 
        .quantity = "500",
        .unit = "g",
        .phase = "dough",
        .raw_line = "500g flour",
        .confidence = 0.95
    };
    try std.testing.expect(i.confidence == 0.95);

    const r = ParseResult{
        .title = "test",
        .description = "",
        .yeast_type = "sourdough",
        .ingredients = &.{},
        .instructions = &.{},
        .metadata = null,
        .confidence = undefined,
        .parse_errors = &.{}
    };
    try std.testing.expectEqualStrings("sourdough", r.yeast_type);
}
