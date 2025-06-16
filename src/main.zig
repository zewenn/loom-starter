const std = @import("std");
const loom = @import("loom");

const build_defs = @cImport({});
const prefabs = @import("prefabs.zig");

pub fn main() void {
    loom.project(.{
        .window = .{
            .title = "Loom Starter",
        },
        .asset_paths = .{
            .debug = build_defs.LOOM_DEBUG_ASSET_PATH,
            .release = build_defs.LOOM_RELEASE_ASSET_PATH,
        },
    })({
        loom.scene("default")({
            loom.prefabs(&.{
                try prefabs.MissingNo(.init(0, 0)),
            });
        });
    });
}
