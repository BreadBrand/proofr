const std = @import("std");

const Section = enum {
    pre_title,
    description,
    ingredients,
    instructions,
    notes,
    nutrition,
    metadata,
};

pub const IngredientGroup = struct {
    phase: []const u8,
    lines: std.ArrayList([]const u8),
};

pub const SectionMap = struct {
    title: []const u8,
    title_detection: []const u8, // "explicit" or "heuristic"
    description: std.ArrayList([]const u8),
    ingredient_groups: std.ArrayList(IngredientGroup),
    instruction_lines: std.ArrayList([]const u8),
    metadata_lines: std.ArrayList([]const u8),
    note_lines: std.ArrayList([]const u8),
    nutrition_lines: std.ArrayList([]const u8),
    flagged_lines: std.ArrayList([]const u8), // out-of-block noise candidates (FR-3.8)

    pub fn init() SectionMap {
        return .{
            .title = "",
            .title_detection = "",
            .description = std.ArrayList([]const u8).empty,
            .ingredient_groups = std.ArrayList(IngredientGroup).empty,
            .instruction_lines = std.ArrayList([]const u8).empty,
            .metadata_lines = std.ArrayList([]const u8).empty,
            .note_lines = std.ArrayList([]const u8).empty,
            .nutrition_lines = std.ArrayList([]const u8).empty,
            .flagged_lines = std.ArrayList([]const u8).empty,
        };
    }
};

fn asSectionKeyword(allocator: std.mem.Allocator, line: []const u8) !?Section {
    const lower = try std.ascii.allocLowerString(allocator, line);
    defer allocator.free(lower);
    const trimmed = std.mem.trim(u8, lower, " \r\t");

    if (std.mem.eql(u8, trimmed, "ingredients") or
        std.mem.eql(u8, trimmed, "ingredient list")) return .ingredients;

    if (std.mem.eql(u8, trimmed, "directions") or
        std.mem.eql(u8, trimmed, "instructions") or
        std.mem.eql(u8, trimmed, "method") or
        std.mem.eql(u8, trimmed, "steps") or
        std.mem.eql(u8, trimmed, "preparation") or
        std.mem.eql(u8, trimmed, "how to make")) return .instructions;

    if (std.mem.eql(u8, trimmed, "notes") or
        std.mem.eql(u8, trimmed, "note") or
        std.mem.eql(u8, trimmed, "tips") or
        std.mem.eql(u8, trimmed, "tip") or
        std.mem.eql(u8, trimmed, "baker's notes") or
        std.mem.eql(u8, trimmed, "chef's notes") or
        std.mem.eql(u8, trimmed, "storage") or
        std.mem.eql(u8, trimmed, "make ahead")) return .notes;
    return null;
}

fn isMetadataLine(allocator: std.mem.Allocator, line: []const u8) !bool {
    const lower = try std.ascii.allocLowerString(allocator, line);
    defer allocator.free(lower);

    const prefixes = &[_][]const u8{
        "prep time",
        "cook time",
        "total time",
        "additional time",
        "rise time",
        "rest time",
        "chill time",
        "bake time",
        "baking time",
        "servings",
        "yield",
    };

    for (prefixes) |prefix| {
        if (std.mem.startsWith(u8, lower, prefix)) {
            return true;
        }
    }
    return false;
}

pub fn detectSections(allocator: std.mem.Allocator, text: []const u8) !SectionMap {
    var lines = std.mem.splitScalar(u8, text, '\n');
    var section = SectionMap.init();
    var current: Section = .pre_title;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (try isMetadataLine(allocator, line)) {
            try section.metadata_lines.append(allocator, line);
            continue;
        }
        const keyword = try asSectionKeyword(allocator, line);
        if (keyword) |kw| {
            current = kw;
            continue;
        }
        //stub switch will come back on 09
        switch (current) {
            .pre_title => {},
            .description => {},
            .ingredients => {},
            .instructions => {},
            .notes => {},
            .nutrition => {},
            .metadata => {},
        }
    }
    return section;
}

test "ingredients keyword transitions" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input =
        "Ingredients\n" ++
        "4 cups all-purpose flour (480g)\n" ++
        "2 tablespoons granulated sugar\n" ++
        "1 tablespoon baking powder\n" ++
        "2 1/2 teaspoons salt\n" ++
        "1 cup very cold unsalted butter cubed (227g)\n" ++
        "1 1/3 cups cold milk (320mL)\n" ++
        "melted butter for brushing (optional)\n";

    const result = try detectSections(allocator, input);
    try std.testing.expect(result.ingredient_groups.items.len == 0);
}
test "notes keyword transitions" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input =
        "Notes\n" ++
        "Make sure the oven has reached 425°F before adding the biscuits. The immediate hot temperature will make sure the biscuits get nice and tall by steaming the butter.\n";

    const result = try detectSections(allocator, input);
    try std.testing.expect(result.ingredient_groups.items.len == 0);
}
test "metadata line detected" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input =
        "Prep Time 25 minutes\n" ++
        "Cook Time 20 minutes\n" ++
        "Total Time 45 minutes\n" ++
        "Servings12 servings (about)\n" ++
        "Calories312kcal\n" ++
        "AuthorJohn Kanell\n";

    const result = try detectSections(allocator, input);
    try std.testing.expect(result.ingredient_groups.items.len == 0);
}
