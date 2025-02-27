const std = @import("std");
const rl = @import("raylib");

pub fn screenWidthFloat() f32 {
    return @floatFromInt(rl.getScreenWidth());
}

pub fn screenHeightFloat() f32 {
    return @floatFromInt(rl.getScreenHeight());
}

pub fn deltaTime() f32 {
    return rl.getFrameTime();
}

pub const Wall = struct {
    rect: rl.Rectangle,

    pub fn init(x: f32, y: f32, w: f32, h: f32) Wall {
        return .{
            .rect = .{
                .x = x,
                .y = y,
                .width = w,
                .height = h,
            },
        };
    }

    pub fn draw(self: Wall) void {
        rl.drawRectangleRec(self.rect, rl.Color.ray_white);
    }

    pub fn isColliding(self: Wall, other: Wall) bool {
        return self.rect.checkCollision(other.rect);
    }
};

pub const Player = struct {
    body: rl.Rectangle,
    face: ?rl.Texture2D,
    movement_speed: f32 = 300,
    rotation: f32 = 0,

    pub fn init(body_w: f32, body_h: f32, face_txtr: ?rl.Texture2D) Player {
        return .{
            .body = .{
                .x = 0,
                .y = 0,
                .width = body_w,
                .height = body_h,
            },
            .face = face_txtr,
        };
    }

    pub fn getHitbox(self: Player) Wall {
        return Wall{
            .rect = .{
                .x = self.body.x - (self.body.width/2),
                .y = self.body.y - (self.body.height/2),
                .height = self.body.height,
                .width = self.body.width,
            }
        };
    }

    pub fn update(self: *Player, walls: []const Wall) void {
        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
            self.body.y -= self.movement_speed * deltaTime();
            for (walls) |wall| {
                if (wall.isColliding(self.getHitbox())) {
                    const col_rect = wall.rect.getCollision(self.getHitbox().rect);
                    self.body.y += col_rect.height;
                    break;
                }
            }
        }
        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
            self.body.y += self.movement_speed * deltaTime();
            for (walls) |wall| {
                if (wall.isColliding(self.getHitbox())) {
                    const col_rect = wall.rect.getCollision(self.getHitbox().rect);
                    self.body.y -= col_rect.height;
                    break;
                }
            }
        }
        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
            self.body.x -= self.movement_speed * deltaTime();
            for (walls) |wall| {
                if (wall.isColliding(self.getHitbox())) {
                    const col_rect = wall.rect.getCollision(self.getHitbox().rect);
                    self.body.x += col_rect.width;
                    break;
                }
            }
        }
        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
            self.body.x += self.movement_speed * deltaTime();
            for (walls) |wall| {
                if (wall.isColliding(self.getHitbox())) {
                    const col_rect = wall.rect.getCollision(self.getHitbox().rect);
                    self.body.x -= col_rect.width;
                    break;
                }
            }
        }

        if (rl.isKeyDown(.comma)) {
            self.rotation -= 50 * deltaTime();
        }
        if (rl.isKeyDown(.period)) {
            self.rotation += 50 * deltaTime();
        }
        if (self.rotation >= 360) {
            self.rotation = 0;
        }
        if (self.rotation < 0) {
            self.rotation = 359;
        }
    }

    pub fn draw(self: Player) void {
        const drawn_pos = rl.Vector2{
            .x = self.body.width/2,
            .y = self.body.height/2,
        };
        rl.drawRectanglePro(self.body, drawn_pos, self.rotation, rl.Color.red);
        if (self.face) |txtr| {
            txtr.drawPro(rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(txtr.width),
                .height = @floatFromInt(txtr.height),
            }, self.body, drawn_pos, self.rotation, rl.Color.white);
        }
    }

    pub fn deinit(self: *Player) void {
        if (self.face) |txtr| {
            txtr.unload();
            self.face = null;
        }
    }
};
