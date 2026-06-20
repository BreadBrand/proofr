pub const packages = struct {
    pub const @"httpz-0.0.0-PNVzrOreCAC0t9K_s6_JqBYK3RpsD_7gcUuI-Dxc3gy8" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/httpz-0.0.0-PNVzrOreCAC0t9K_s6_JqBYK3RpsD_7gcUuI-Dxc3gy8";
        pub const build_zig = @import("httpz-0.0.0-PNVzrOreCAC0t9K_s6_JqBYK3RpsD_7gcUuI-Dxc3gy8");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "metrics", "metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66" },
            .{ "websocket", "websocket-0.1.0-ZPISdaXaBADnMkB-sc_PBK4Ri0DX2AyxIJsAgWFIicUH" },
        };
    };
    pub const @"metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66";
        pub const build_zig = @import("metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"websocket-0.1.0-ZPISdaXaBADnMkB-sc_PBK4Ri0DX2AyxIJsAgWFIicUH" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/websocket-0.1.0-ZPISdaXaBADnMkB-sc_PBK4Ri0DX2AyxIJsAgWFIicUH";
        pub const build_zig = @import("websocket-0.1.0-ZPISdaXaBADnMkB-sc_PBK4Ri0DX2AyxIJsAgWFIicUH");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "httpz", "httpz-0.0.0-PNVzrOreCAC0t9K_s6_JqBYK3RpsD_7gcUuI-Dxc3gy8" },
};
