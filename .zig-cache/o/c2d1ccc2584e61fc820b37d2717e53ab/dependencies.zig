pub const packages = struct {
    pub const @"httpz-0.0.0-PNVzrILKCADcKBmMLyKYRo0XAUPVMeUvkOLpsdiSkH-I" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/httpz-0.0.0-PNVzrILKCADcKBmMLyKYRo0XAUPVMeUvkOLpsdiSkH-I";
        pub const build_zig = @import("httpz-0.0.0-PNVzrILKCADcKBmMLyKYRo0XAUPVMeUvkOLpsdiSkH-I");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "metrics", "metrics-0.0.0-W7G4eIegAQD4XxA9Co7Atbw59u_2zvxYf406AZuoAHPM" },
            .{ "websocket", "websocket-0.1.0-ZPISdX_aBAA8KKbCxFr_Y-uaO6w2WyT7qEi1Xe_4JIbo" },
        };
    };
    pub const @"metrics-0.0.0-W7G4eIegAQD4XxA9Co7Atbw59u_2zvxYf406AZuoAHPM" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/metrics-0.0.0-W7G4eIegAQD4XxA9Co7Atbw59u_2zvxYf406AZuoAHPM";
        pub const build_zig = @import("metrics-0.0.0-W7G4eIegAQD4XxA9Co7Atbw59u_2zvxYf406AZuoAHPM");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"websocket-0.1.0-ZPISdX_aBAA8KKbCxFr_Y-uaO6w2WyT7qEi1Xe_4JIbo" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/websocket-0.1.0-ZPISdX_aBAA8KKbCxFr_Y-uaO6w2WyT7qEi1Xe_4JIbo";
        pub const build_zig = @import("websocket-0.1.0-ZPISdX_aBAA8KKbCxFr_Y-uaO6w2WyT7qEi1Xe_4JIbo");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "httpz", "httpz-0.0.0-PNVzrILKCADcKBmMLyKYRo0XAUPVMeUvkOLpsdiSkH-I" },
};
