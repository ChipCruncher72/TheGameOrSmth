const std = @import("std");
const rl = @import("raylib");
const game = struct {
    const objects = @import("game_objects.zig");
    const Stage1 = @import("stage1.zig");
};

const Fullscreen = struct {
    is_fullscreen: bool = false,
    before_window_pos: rl.Vector2,
    before_window_width: i32,
    before_window_height: i32,

    pub fn init() Fullscreen {
        return .{
            .before_window_pos = rl.getWindowPosition(),
            .before_window_width = rl.getScreenWidth(),
            .before_window_height = rl.getScreenHeight(),
        };
    }

    pub fn toggle(fs: *Fullscreen) void {
        if (!fs.is_fullscreen) {
            fs.before_window_pos = rl.getWindowPosition();
            fs.before_window_height = rl.getScreenHeight();
            fs.before_window_width = rl.getScreenWidth();
            fs.is_fullscreen = true;
            rl.setWindowState(.{ .window_undecorated = true });
            rl.setWindowPosition(0, 0);
            rl.setWindowSize(rl.getMonitorWidth(rl.getCurrentMonitor()), rl.getMonitorHeight(rl.getCurrentMonitor()));
        } else {
            fs.is_fullscreen = false;
            rl.clearWindowState(.{ .window_undecorated = true });
            rl.setWindowPosition(@intFromFloat(fs.before_window_pos.x), @intFromFloat(fs.before_window_pos.y));
            rl.setWindowSize(fs.before_window_width, fs.before_window_height);
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    rl.setTraceLogLevel(.none);

    rl.setConfigFlags(.{ .window_resizable = true, .window_always_run = true });

    rl.initWindow(1000, 800, "Game 2: Electric Boogaloo");
    defer rl.closeWindow();

    var fullscreener = Fullscreen.init();

    var stage1 = try game.Stage1.init(allocator);

    var unlimited_fps = stage1.save_data.unlimited_fps;
    rl.setTargetFPS(if (unlimited_fps) 0 else 60);
    defer stage1.deinit(unlimited_fps, fullscreener.is_fullscreen) catch @panic("");

    if (stage1.save_data.fullscreen) {
        fullscreener.toggle();
    }

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.f11)) {
            // NOTE: Use this as opposed to rl.toggleBorderlessWindowed/rl.toggleFullscreen
            //  as those functions do not let you tab out of the window while in fullscreen
            fullscreener.toggle();
        }
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
