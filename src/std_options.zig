const std = @import("std");

// Force enable logging in release builds
// This ensures CLI help and output messages work in ReleaseFast builds
pub const log_level: std.log.Level = .info;
