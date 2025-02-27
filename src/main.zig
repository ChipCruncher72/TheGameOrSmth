const std = @import("std");
const rl = @import("raylib");
const game = struct {
    const objects = @import("game_objects.zig");
    const Stage1 = @import("stage1.zig");
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    rl.setTraceLogLevel(.none);

    rl.setConfigFlags(.{ .window_resizable = true, .window_always_run = true });

    rl.initWindow(1000, 800, "Game 2: Electric Boogaloo");
    defer rl.closeWindow();

    var unlimited_fps = false;
    rl.setTargetFPS(if (unlimited_fps) 0 else 60);

    var stage1 = try game.Stage1.init(allocator);
    defer stage1.deinit();

    while (!rl.windowShouldClose() or rl.isKeyDown(.escape)) {
        if (rl.isKeyPressed(.u)) {
            unlimited_fps = !unlimited_fps;
            rl.setTargetFPS(if (unlimited_fps) 0 else 60);
        }

        stage1.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        stage1.camera.begin();

        stage1.drawReal();

        stage1.camera.end();

        try stage1.drawUI();
    }
}
