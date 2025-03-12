const std = @import("std");
const rl = @import("raylib");
const objects = @import("game_objects.zig");
const Self = @This();
const ArrayList = std.ArrayListUnmanaged;

pub const SaveData = struct {
    player_data: struct {
        anim_stage: f32,
        rotation: f32,
        x: f32,
        y: f32,
    },
    camera_zoom: f32,
    debug_enabled: bool,
    fullscreen: bool,
    unlimited_fps: bool,
};

player: objects.Player,
walls: ArrayList(objects.Wall),
camera: rl.Camera2D,
allocator: std.mem.Allocator,
arena_allocator: std.heap.ArenaAllocator,
save_data: SaveData,
username: ?[]const u8,
draw_debug_info: bool,


fn loadSave(allocator: std.mem.Allocator) !SaveData {
    const file = std.fs.cwd().openFile("save.dat", .{}) catch |e| blk: {
        if (e != error.FileNotFound) return e;

        const created_file = try std.fs.cwd().createFile("save.dat", .{});
        defer created_file.close();

        try created_file.writeAll(
            \\// ===============================================================
            \\// DO NOT TOUCH THIS FILE
            \\// IT IS USED FOR KEEPING TRACK OF GAME STATE
            \\// TOUCHING THIS FILE WILL VOID ANY WARRANTY THAT YOU MIGHT'VE HAD
            \\// ===============================================================
            \\.{
            \\    .player_data = .{
            \\        .anim_stage = 0.0,
            \\        .rotation = 0.0,
            \\        .x = 0.0,
            \\        .y = 0.0,
            \\    },
            \\    .camera_zoom = 1.0,
            \\    .debug_enabled = false,
            \\    .fullscreen = false,
            \\    .unlimited_fps = false,
            \\}
        );

        break :blk try std.fs.cwd().openFile("save.dat", .{});
    };
    defer file.close();

    const content = try allocator.allocSentinel(u8, try file.getEndPos(), 0);
    defer allocator.free(content);

    _ = try file.readAll(content);

    return try std.zon.parse.fromSlice(SaveData, allocator, content, null, .{});
}

fn putSave(data: SaveData) !void {
    const file = try std.fs.cwd().createFile("save.dat", .{});
    defer file.close();

    try file.writeAll(
        \\// ===============================================================
        \\// DO NOT TOUCH THIS FILE
        \\// IT IS USED FOR KEEPING TRACK OF GAME STATE
        \\// TOUCHING THIS FILE WILL VOID ANY WARRANTY THAT YOU MIGHT'VE HAD
        \\// ===============================================================
        \\
    );

    try std.zon.stringify.serialize(data, .{}, file.writer());
}

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
        .save_data = undefined,
        .draw_debug_info = false,
    };
    self.save_data = try loadSave(allocator);
    self.player.body.x = self.save_data.player_data.x;
    self.player.body.y = self.save_data.player_data.y;
    self.player.rotation = self.save_data.player_data.rotation;
    self.player.face.?.draw_x = self.save_data.player_data.anim_stage;
    self.draw_debug_info = self.save_data.debug_enabled;

    self.camera = .{
        .target = .{
            .x = self.player.body.x,
            .y = self.player.body.y,
        },
        .offset = .{
            .x = objects.screenWidthFloat()/2,
            .y = objects.screenHeightFloat()/2,
        },
        .zoom = self.save_data.camera_zoom,
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

pub fn deinit(self: *Self, unlimited_fps: bool, fullscreen: bool) !void {
    self.save_data.camera_zoom = self.camera.zoom;
    self.save_data.player_data.x = self.player.body.x;
    self.save_data.player_data.y = self.player.body.y;
    self.save_data.player_data.rotation = self.player.rotation;
    self.save_data.player_data.anim_stage = self.player.face.?.draw_x;
    self.save_data.debug_enabled = self.draw_debug_info;
    self.save_data.unlimited_fps = unlimited_fps;
    self.save_data.fullscreen = fullscreen;

    try putSave(self.save_data);

    std.zon.parse.free(self.allocator, self.save_data);

    if (self.username) |user| {
        self.allocator.free(user);
        self.username = null;
    }
    self.player.deinit();
    self.walls.deinit(self.allocator);
    self.arena_allocator.deinit();
}
