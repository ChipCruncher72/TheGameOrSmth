const std = @import("std");
const rl = @import("raylib");

pub fn screenWidthFloat() f32 {
    return @floatFromInt(rl.getScreenWidth());
}

pub fn screenHeightFloat() f32 {
    return @floatFromInt(rl.getScreenHeight());
}

pub const deltaTime = rl.getFrameTime;

pub const RateLimiter = struct {
    last_update_time: f64 = 0,
    limit: f64,

    pub fn init(limit_seconds: f64) RateLimiter {
        return .{
            .limit = limit_seconds,
        };
    }

    pub fn check(self: *RateLimiter) bool {
        const current_time = rl.getTime();
        if (current_time - self.last_update_time >= self.limit) {
            self.last_update_time = current_time;
            return true;
        }
        return false;
    }
};

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

pub const Face = struct {
    txtr: rl.Texture2D,
    draw_x: f32 = 0,
    draw_y: f32 = 0,
    draw_width: f32,
    draw_height: f32,
    sprite_chunks: f32,

    pub fn init(txtr: rl.Texture2D, sprite_chunks: f32) Face {
        var self = Face{
            .txtr = txtr,
            .sprite_chunks = sprite_chunks,
            .draw_width = undefined,
            .draw_height = undefined,
        };
        self.draw_width = @as(f32, @floatFromInt(txtr.width))/sprite_chunks;
        self.draw_height = @floatFromInt(txtr.height);
        return self;
    }
};

pub const Player = struct {
    body: rl.Rectangle,
    face: ?Face,
    movement_speed: f32 = 300,
    rotation: f32 = 0,
    limiter: RateLimiter = RateLimiter.init(0.5),

    pub fn init(body_w: f32, body_h: f32, face_txtr: ?rl.Texture2D) Player {
        return .{
            .body = .{
                .x = 0,
                .y = 0,
                .width = body_w,
                .height = body_h,
            },
            .face = if (face_txtr) |txtr| .init(txtr, 2) else null,
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
        var do_update = self.limiter.check();
        if (rl.isKeyDown(.up) or rl.isKeyDown(.w)) {
            self.body.y -= self.movement_speed * deltaTime();
            for (walls) |wall| {
                const hitbox = self.getHitbox();
                if (wall.isColliding(hitbox)) {
                    const col_rect = wall.rect.getCollision(hitbox.rect);
                    self.body.y += col_rect.height;
                    break;
                }
            }
            if (do_update and self.face != null) {
                const face = &self.face.?;
                face.draw_x = if (face.draw_x == 0) face.draw_width else 0;
                do_update = false;
            }
        }
        if (rl.isKeyDown(.down) or rl.isKeyDown(.s)) {
            self.body.y += self.movement_speed * deltaTime();
            for (walls) |wall| {
                const hitbox = self.getHitbox();
                if (wall.isColliding(hitbox)) {
                    const col_rect = wall.rect.getCollision(hitbox.rect);
                    self.body.y -= col_rect.height;
                    break;
                }
            }
            if (do_update and self.face != null) {
                const face = &self.face.?;
                face.draw_x = if (face.draw_x == 0) face.draw_width else 0;
                do_update = false;
            }
        }
        if (rl.isKeyDown(.left) or rl.isKeyDown(.a)) {
            self.body.x -= self.movement_speed * deltaTime();
            for (walls) |wall| {
                const hitbox = self.getHitbox();
                if (wall.isColliding(hitbox)) {
                    const col_rect = wall.rect.getCollision(hitbox.rect);
                    self.body.x += col_rect.width;
                    break;
                }
            }
            if (do_update and self.face != null) {
                const face = &self.face.?;
                face.draw_x = if (face.draw_x == 0) face.draw_width else 0;
                do_update = false;
            }
        }
        if (rl.isKeyDown(.right) or rl.isKeyDown(.d)) {
            self.body.x += self.movement_speed * deltaTime();
            for (walls) |wall| {
                const hitbox = self.getHitbox();
                if (wall.isColliding(hitbox)) {
                    const col_rect = wall.rect.getCollision(hitbox.rect);
                    self.body.x -= col_rect.width;
                    break;
                }
            }
            if (do_update and self.face != null) {
                const face = &self.face.?;
                face.draw_x = if (face.draw_x == 0) face.draw_width else 0;
                do_update = false;
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

        if (rl.isKeyPressed(.r)) {
            self.rotation = 0;
        }
    }

    pub fn draw(self: Player) void {
        const drawn_pos = rl.Vector2{
            .x = self.body.width/2,
            .y = self.body.height/2,
        };
        rl.drawRectanglePro(self.body, drawn_pos, self.rotation, rl.Color.red);
        if (self.face) |face| {
            face.txtr.drawPro(rl.Rectangle{
                .x = face.draw_x,
                .y = face.draw_y,
                .width = face.draw_width,
                .height = face.draw_height,
            }, self.body, drawn_pos, self.rotation, rl.Color.white);
        }
    }

    pub fn deinit(self: *Player) void {
        if (self.face) |face| {
            face.txtr.unload();
            self.face = null;
        }
    }
};
