const std = @import("std");

const UnitEntry = struct {
    canonical: []const u8,
    variants: []const []const u8,
};

const unit_table = &[_]UnitEntry{
    .{ .canonical = "g", .variants = &[_][]const u8{ "gram", "grams", "g" } },
    .{ .canonical = "kg", .variants = &[_][]const u8{ "kilogram", "kilograms", "kg" } },
    .{ .canonical = "oz", .variants = &[_][]const u8{ "ounce", "ounces", "oz" } },
    .{ .canonical = "fl oz", .variants = &[_][]const u8{  "fluid ounce", "fluid ounces", "fl oz" } },
    .{ .canonical = "lb", .variants = &[_][]const u8{ "pound", "pounds", "lb", "lbs" } },
    .{ .canonical = "ml", .variants = &[_][]const u8{ "milliliter", "millilitre", "milliliters", "millilitres", "ml" } },
    .{ .canonical = "l", .variants = &[_][]const u8{ "liter", "litre", "liters", "litres", "l" } },
    .{ .canonical = "tsp", .variants = &[_][]const u8{ "teaspoon", "teaspoons", "tsp" } },
    .{ .canonical = "tbsp", .variants = &[_][]const u8{ "tablespoon", "tablespoons", "tbsp", "tbs" } },
    .{ .canonical = "cup", .variants = &[_][]const u8{ "cup", "cups", "c" } },
    .{ .canonical = "pinch", .variants = &[_][]const u8{"pinch"} },
    .{ .canonical = "handful", .variants = &[_][]const u8{"handful"} },
    .{ .canonical = "dash", .variants = &[_][]const u8{"dash"} },
    .{ .canonical = "sprig", .variants = &[_][]const u8{"sprig"} },
    .{ .canonical = "clove", .variants = &[_][]const u8{"clove"} },
    .{ .canonical = "slice", .variants = &[_][]const u8{"slice"} },
    .{ .canonical = "piece", .variants = &[_][]const u8{"piece"} },
    .{ .canonical = "bunch", .variants = &[_][]const u8{"bunch"} },
};

pub fn matchUnit(word: []const u8) ?[]const u8 {
    var buf: [32]u8 = undefined;
    const lower = std.ascii.lowerString(&buf, word);
    for (unit_table) |unit| {
        for (unit.variants) |variant| {
            if (std.mem.eql(u8, variant, lower)) return unit.canonical;
        }
    }
    return null;
}

pub fn matchUnitPrefix(words: []const []const u8) ?struct { canonical: []const u8, consumed: u8 } {
    if (words.len >= 2) {
        const w1 = words[0];
        const w2 = words[1];

        var combined: [65]u8 = undefined;
        const joined = std.fmt.bufPrint(&combined, "{s} {s}", .{ w1, w2 }) catch return null;
        if (matchUnit(joined)) |canonical| {
            return .{ .canonical = canonical, .consumed = 2 };
        }
    }

    if (words.len >= 1) {
        if (matchUnit(words[0])) |canonical| {
            return .{ .canonical = canonical, .consumed = 1 };
        }
    }
    return null;
}

test "gram variants" {
    try std.testing.expectEqualStrings("g", matchUnit("grams").?);
    try std.testing.expectEqualStrings("g", matchUnit("gram").?);
    try std.testing.expectEqualStrings("g", matchUnit("g").?);
}
test "tablespoon" {
    try std.testing.expectEqualStrings("tbsp", matchUnit("tablespoon").?);
    try std.testing.expectEqualStrings("tbsp", matchUnit("tablespoons").?);
    try std.testing.expectEqualStrings("tbsp", matchUnit("tbsp").?);
    try std.testing.expectEqualStrings("tbsp", matchUnit("tbs").?);
}
test "fl oz" {
    const words1 = &[_][]const u8{"fluid", "ounces"};
    const words2 = &[_][]const u8{"fluid", "ounce"};
    const words3 = &[_][]const u8{"fl", "oz"};
    try std.testing.expectEqualStrings("fl oz", matchUnitPrefix(words1).?.canonical);
    try std.testing.expectEqualStrings("fl oz", matchUnitPrefix(words2).?.canonical);
    try std.testing.expectEqualStrings("fl oz", matchUnitPrefix(words3).?.canonical);
}
test "no match" {
    try std.testing.expectEqualStrings("pinch", matchUnit("pinch").?);
}
test "no match garbage" {
    try std.testing.expect(matchUnit("xyz") == null);
}
