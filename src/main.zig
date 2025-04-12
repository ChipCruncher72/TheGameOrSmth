const std = @import("std");
const rl = @import("raylib");
const game = struct {
    const objects = @import("game_objects.zig");
    const Stage1 = @import("stage1.zig");
};
const c_headers = @import("c_headers");

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

var debug_allocator = std.heap.DebugAllocator(.{}).init;
const AutoAllocator = struct {
    allocator: std.mem.Allocator,
    is_debug: bool,

    pub const init = if (@import("builtin").os.tag == .wasi) AutoAllocator{
        .allocator = std.heap.wasm_allocator,
        .is_debug = false,
    } else switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => AutoAllocator{
            .allocator = debug_allocator.allocator(),
            .is_debug = true,
        },
        else => AutoAllocator{
            .allocator = std.heap.smp_allocator,
            .is_debug = false,
        },
    };

    pub fn deinit(self: AutoAllocator) void {
        if (self.is_debug) {
            _ = debug_allocator.deinit();
        }
    }
};

pub fn main() !void {
    _ = c_headers.freopen("output.log", "w", c_headers.get_stdout());
    _ = c_headers.freopen("output.log", "w", c_headers.get_stderr());

    realMain() catch |err| {
        const output_log = try std.fs.cwd().createFile("output.log", .{});
        defer output_log.close();

        const writer = output_log.writer();

        const err_trace = @errorReturnTrace();

        try writer.print("{}\n", .{err});

        if (err_trace) |trace| {
            try writer.print("{}\n", .{trace});
        }

        return err;
    };
}

pub fn realMain() !void {
    const auto_alloc = AutoAllocator.init;
    defer auto_alloc.deinit();

    const allocator = auto_alloc.allocator;

    rl.setTraceLogLevel(.all);

    rl.setConfigFlags(.{ .window_resizable = true, .window_always_run = true });

    rl.initWindow(1000, 800, "Game 2: Electric Boogaloo");
    defer rl.closeWindow();

    var fullscreener = Fullscreen.init();

    var save_data = try game.objects.loadSave(allocator);
    defer std.zon.parse.free(allocator, save_data);

    var unlimited_fps = save_data.unlimited_fps;
    rl.setTargetFPS(if (unlimited_fps) 0 else 60);

    if (save_data.fullscreen) {
        fullscreener.toggle();
    }

    var stage1 = try game.Stage1.init(allocator);
    defer stage1.deinit();

    stage1.player.body.x = save_data.player_data.x;
    stage1.player.body.y = save_data.player_data.y;
    stage1.player.rotation = save_data.player_data.rotation;
    stage1.player.face.?.draw_x = save_data.player_data.anim_stage;
    stage1.camera.zoom = save_data.camera_zoom;
    stage1.draw_debug_info = save_data.debug_enabled;

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

    save_data.unlimited_fps = unlimited_fps;
    save_data.fullscreen = fullscreener.is_fullscreen;
    save_data.player_data.x = stage1.player.body.x;
    save_data.player_data.y = stage1.player.body.y;
    save_data.player_data.rotation = stage1.player.rotation;
    save_data.player_data.anim_stage = stage1.player.face.?.draw_x;
    save_data.camera_zoom = stage1.camera.zoom;
    save_data.debug_enabled = stage1.draw_debug_info;

    try game.objects.putSave(allocator, save_data);
}

pub const panic = std.debug.FullPanic(panicFn);

pub fn panicFn(msg: []const u8, first_trace_addr: ?usize) noreturn {
    const output_log = std.fs.cwd().createFile("output.log", .{}) catch std.process.exit(1);

    const writer = output_log.writer();

    writer.print("Panic! {s}\n", .{msg}) catch std.process.exit(1);

    const debug_info = std.debug.getSelfDebugInfo() catch std.process.exit(1);
    std.debug.writeCurrentStackTrace(writer, debug_info, std.io.tty.detectConfig(output_log), first_trace_addr) catch std.process.exit(1);

    std.process.exit(1);
}
