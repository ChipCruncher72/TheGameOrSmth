const std = @import("std");
const rl = @import("raylib");
const objects = @import("game_objects.zig");
const Self = @This();

player: objects.Player,
walls: std.ArrayList(objects.Wall),
camera: rl.Camera2D,
draw_dbg_info: bool,
allocator: std.mem.Allocator,
arena_allocator: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator) !Self {
    const player_face = try rl.Texture2D.init("assets/guy.png");
    var self = Self{
        .player = objects.Player.init(45, 45, player_face),
        .walls = try std.ArrayList(objects.Wall).initCapacity(allocator, 100),
        .allocator = allocator,
        .camera = undefined,
        .draw_dbg_info = false,
        .arena_allocator = std.heap.ArenaAllocator.init(allocator),
    };
    self.camera = .{
        .target = .{
            .x = self.player.body.x,
            .y = self.player.body.y,
        },
        .offset = .{
            .x = objects.screenWidthFloat()/2,
            .y = objects.screenHeightFloat()/2,
        },
        .zoom = 1,
        .rotation = 0,
    };
    for ([_]objects.Wall{
        objects.Wall.init(100, 100, 200, 30),
        objects.Wall.init(100, -100, 30, 200),
    }) |wall| {
        try self.walls.append(wall);
    }
    return self;
}

pub fn update(self: *Self) void {
    if (rl.isKeyPressed(.f1)) {
        self.draw_dbg_info = !self.draw_dbg_info;
    }

    if (rl.isKeyDown(.equal)) {
        self.camera.zoom += 3 * objects.deltaTime();
    }
    if (rl.isKeyDown(.minus)) {
        self.camera.zoom -= 3 * objects.deltaTime();
    }
    if (self.camera.zoom < 0) {
        self.camera.zoom = 0;
    }

    self.player.update(self.walls.items);
    self.camera.target = .{
        .x = self.player.body.x,
        .y = self.player.body.y,
    };
    self.camera.offset = .{
        .x = objects.screenWidthFloat()/2,
        .y = objects.screenHeightFloat()/2,
    };
}

pub fn drawUI(self: *Self) !void {
    if (self.draw_dbg_info) {
        const allocator = self.arena_allocator.allocator();
        defer _ = self.arena_allocator.reset(.retain_capacity);

        const x_pos = try std.fmt.allocPrintZ(allocator, "X: {d:.1}", .{self.player.body.x});
        const y_pos = try std.fmt.allocPrintZ(allocator, "Y: {d:.1}", .{self.player.body.y});
        const cam_zoom = try std.fmt.allocPrintZ(allocator, "ZOOM: {d:.1}", .{self.camera.zoom});
        const fps_count = try std.fmt.allocPrintZ(allocator, "FPS: {d}", .{rl.getFPS()});
        const rotation = try std.fmt.allocPrintZ(allocator, "ROT: {d:.1}", .{self.player.rotation});
        const name = try std.fmt.allocPrintZ(allocator, "NAME: {s}", .{
            std.process.getEnvVarOwned(allocator, "USERNAME") catch |e|
                if (e == error.EnviromentVariableNotFound)
                    std.process.getEnvVarOwned(allocator, "USER") catch |e2|
                        if (e2 == error.EnviromentVariableNotFound) "Unknown" else "CANT GET"
                else
                    "CANT GET"
        });

        rl.drawText(x_pos, 10, 10, 30, rl.Color.white);
        rl.drawText(y_pos, 10, 45, 30, rl.Color.white);
        rl.drawText(cam_zoom, 10, 80, 30, rl.Color.white);
        rl.drawText(fps_count, 10, 115, 30, rl.Color.white);
        rl.drawText(rotation, 10, 150, 30, rl.Color.white);
        rl.drawText(name, 10, 185, 30, rl.Color.white);
    }
}

pub fn drawReal(self: Self) void {
    for (self.walls.items) |wall| {
        wall.draw();
    }
    self.player.draw();
}

pub fn deinit(self: *Self) void {
    self.player.deinit();
    self.walls.deinit();
    self.arena_allocator.deinit();
}
