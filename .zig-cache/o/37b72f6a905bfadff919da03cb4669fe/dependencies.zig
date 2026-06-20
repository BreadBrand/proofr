pub const packages = struct {
    pub const @"httpz-0.0.0-PNVzrFzKCABcvXEwdGT-nmljcDL0JSAVsssRjKLHT5GE" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/httpz-0.0.0-PNVzrFzKCABcvXEwdGT-nmljcDL0JSAVsssRjKLHT5GE";
        pub const build_zig = @import("httpz-0.0.0-PNVzrFzKCABcvXEwdGT-nmljcDL0JSAVsssRjKLHT5GE");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "metrics", "metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66" },
            .{ "websocket", "websocket-0.1.0-ZPISdXzaBADSWV1KAQnIxkRyS2BTzoZdSHIyrBYNxfyY" },
        };
    };
    pub const @"metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66";
        pub const build_zig = @import("metrics-0.0.0-W7G4eKXEAQDnX3LGPHFttHEV1nQn934f_shdK7p3BW66");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"websocket-0.1.0-ZPISdXzaBADSWV1KAQnIxkRyS2BTzoZdSHIyrBYNxfyY" = struct {
        pub const build_root = "/home/bash/Dev/proofr/zig-pkg/websocket-0.1.0-ZPISdXzaBADSWV1KAQnIxkRyS2BTzoZdSHIyrBYNxfyY";
        pub const build_zig = @import("websocket-0.1.0-ZPISdXzaBADSWV1KAQnIxkRyS2BTzoZdSHIyrBYNxfyY");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "httpz", "httpz-0.0.0-PNVzrFzKCABcvXEwdGT-nmljcDL0JSAVsssRjKLHT5GE" },
};
