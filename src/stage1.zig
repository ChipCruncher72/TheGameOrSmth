const std = @import("std");
const rl = @import("raylib");
const objects = @import("game_objects.zig");
const Self = @This();
const ArrayList = std.ArrayListUnmanaged;

player: objects.Player,
walls: ArrayList(objects.Wall),
camera: rl.Camera2D,
allocator: std.mem.Allocator,
arena_allocator: std.heap.ArenaAllocator,
username: ?[]const u8,
draw_debug_info: bool,

pub fn init(allocator: std.mem.Allocator) !Self {
    const player_face = try rl.Texture2D.init("assets/guy.png");
    var self = Self{
        .player = .init(45, 45, player_face),
        .walls = try .initCapacity(allocator, 100),
        .allocator = allocator,
        .camera = undefined,
        .arena_allocator = .init(allocator),
        .username = std.process.getEnvVarOwned(allocator, "USERNAME") catch |e|
            if (e == error.EnviromentVariableNotFound)
                std.process.getEnvVarOwned(allocator, "USER") catch null
            else
                null,
        .draw_debug_info = false,
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
    try self.walls.appendSlice(allocator, &.{
        .init(100, 100, 200, 30),
        .init(100, -100, 30, 200),
    });
    return self;
}

pub fn update(self: *Self) void {
    if (rl.isKeyPressed(.f1)) {
        self.draw_debug_info = !self.draw_debug_info;
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
    if (self.draw_debug_info) {
        const allocator = self.arena_allocator.allocator();
        defer _ = self.arena_allocator.reset(.retain_capacity);

        const x_pos = try std.fmt.allocPrintZ(allocator, "X: {d:.1}", .{self.player.body.x});
        const y_pos = try std.fmt.allocPrintZ(allocator, "Y: {d:.1}", .{self.player.body.y});
        const cam_zoom = try std.fmt.allocPrintZ(allocator, "ZOOM: {d:.1}", .{self.camera.zoom});
        const fps_count = try std.fmt.allocPrintZ(allocator, "FPS: {d}", .{rl.getFPS()});
        const rotation = try std.fmt.allocPrintZ(allocator, "ROT: {d:.1}", .{self.player.rotation});
        const name = try std.fmt.allocPrintZ(allocator, "NAME: {s}", .{self.username orelse "Unknown"});

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
    if (self.username) |user| {
        self.allocator.free(user);
        self.username = null;
    }
    self.player.deinit();
    self.walls.deinit(self.allocator);
    self.arena_allocator.deinit();
}
