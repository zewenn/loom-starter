const std = @import("std");
const loom = @import("loom");

pub fn MissingNo(comptime pos: loom.Vector2) !loom.Prefab {
    return try loom.prefab("missing-no", .{
        loom.Transform{ .position = loom.vec2ToVec3(pos) },
        loom.Renderer.sprite("missingno.png"),
        loom.CameraTarget.init("main", .{}),
    });
}
