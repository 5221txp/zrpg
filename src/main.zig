const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const rand = std.crypto.random;
const time = std.time;
const sleep = std.Thread.sleep;
const screen_width = 640;
const screen_height = 360;

const FIXED_DT: f64 = 1.0 / 24.0;

fn get_current_time() f64 {
    return @as(f64, @floatFromInt(time.milliTimestamp())) / 1000.0;
}

const Direction = enum { left, right, up, down };

const Transform = struct {
    position: rl.Vector2,
    rotation: f32 = 0,
    sx: f32 = 1.0,
    sy: f32 = 1.0,

    pub fn copy(self: *Transform) Transform {
        return .{
            .position = self.position,
            .rotation = self.rotation,
            .sx = self.sx,
            .sy = self.sy,
        };
    }
};

const Sprite = struct {
    texture: []const u8,
    source: rl.Rectangle,
    tint: rl.Color = rl.Color.white,
};

const Tank = struct {
    world: *World,
    sprite: Sprite,
    transform: Transform,
    direction: Direction = .up,
    velocity: f32 = 10,
    moving: bool = false,

    fn update_pos(self: *Tank) void {
        self.transform.position = self.get_next_pos();
    }

    fn get_next_pos(self: *const Tank) rl.Vector2 {
        var new_pos = self.transform.position;
        // if (!self.moving) {
        //     return new_pos;
        // }
        switch (self.direction) {
            .up => {
                new_pos.y -= self.velocity;
            },
            .down => {
                new_pos.y += self.velocity;
            },
            .left => {
                new_pos.x -= self.velocity;
            },
            else => {
                new_pos.x += self.velocity;
            },
        }
        return new_pos;
    }

    pub fn update(self: *Tank, dt: f64) void {
        const prev_moving = self.moving;
        const prev_direction = self.direction;
        self.moving = false;
        if (self.world.input_manager.left_key) {
            self.direction = .left;
            self.moving = true;
            self.transform.rotation = 180;
        }
        if (self.world.input_manager.right_key) {
            self.direction = .right;
            self.moving = true;
            self.transform.rotation = 0;
        }
        if (self.world.input_manager.up_key) {
            self.direction = .up;
            self.moving = true;
            self.transform.rotation = 270;
        }
        if (self.world.input_manager.down_key) {
            self.direction = .down;
            self.moving = true;
            self.transform.rotation = 90;
        }
        // finish interpole move if prev_moving is true
        if (prev_moving) {
            self.update_pos();
        }
        if (prev_direction != self.direction) {
            print("????????", .{});
        }
        print("Update tank with dt {d}\n", .{dt});
    }

    fn get_interpolation_pos(self: *const Tank, alpha: f64) rl.Vector2 {
        var pos = self.transform.position;
        const a: f32 = @floatCast(alpha);
        switch (self.direction) {
            .up => {
                pos.y -= a * self.velocity;
            },
            .down => {
                pos.y += a * self.velocity;
            },
            .left => {
                pos.x -= a * self.velocity;
            },
            else => {
                pos.x += a * self.velocity;
            },
        }
        return pos;
    }

    pub fn render(self: *Tank, alpha: f64) void {
        // const render_pos = if (self.moving) self.get_interpolation_pos(alpha) else self.transform.position;
        var render_pos = self.transform.position;
        if (self.moving) {
            const next_pos = self.get_next_pos();
            render_pos = self.transform.position.lerp(next_pos, @floatCast(alpha));
        }
        print(
            "Render tank with alpha {d}, physic pos ({d}, {d}), render pos ({d}, {d})\n",
            .{
                alpha,
                self.transform.position.x,
                self.transform.position.y,
                render_pos.x,
                render_pos.y,
            },
        );
        rl.drawTexturePro(
            self.world.resource_manager.textures.get(self.sprite.texture).?,
            self.sprite.source,
            rl.Rectangle{
                .x = render_pos.x,
                .y = render_pos.y,
                .width = self.sprite.source.width,
                .height = self.sprite.source.height,
            },
            rl.Vector2.init(
                self.sprite.source.width / 2,
                self.sprite.source.height / 2,
            ),
            self.transform.rotation,
            self.sprite.tint,
        );
    }
};

const World = struct {
    is_running: bool,
    start_time: f64 = 0,
    current_time: f64 = 0,
    resource_manager: ResourceManager,
    input_manager: InputManager,
    player: ?Tank = null,

    pub fn init(allocator: Allocator) World {
        return World{
            .is_running = false,
            .resource_manager = ResourceManager.init(allocator),
            .input_manager = .{},
        };
    }

    pub fn start(self: *World) void {
        self.is_running = true;
        self.start_time = get_current_time();
        self.current_time = self.start_time;
    }

    pub fn deinit(self: *World) void {
        self.resource_manager.deinit();
    }

    pub fn update(self: *World, dt: f64) void {
        print("Update with dt {d}\n", .{dt});
        self.player.?.update(dt);
    }

    pub fn render(self: *World, alpha: f64) void {
        print("Render with alpha {d}\n", .{alpha});
        self.player.?.render(alpha);
        // sleep(rand.intRangeAtMost(u64, 10, 20) * 1_000_000);
        // sleep(10 * 1_000_000);
    }
};

const ResourceManager = struct {
    textures: std.StringHashMap(rl.Texture2D),

    pub fn init(allocator: Allocator) ResourceManager {
        return .{
            .textures = std.StringHashMap(rl.Texture2D).init(allocator),
        };
    }

    pub fn deinit(self: *ResourceManager) void {
        var txt_iter = self.textures.valueIterator();
        while (txt_iter.next()) |txt| {
            rl.unloadTexture(txt.*);
        }
        self.textures.deinit();
    }

    pub fn load_texture(self: *ResourceManager, imgpath: [:0]const u8, name: []const u8) !void {
        const image = try rl.loadImage(imgpath);
        const texture = try rl.loadTextureFromImage(image);
        rl.unloadImage(image);
        try self.textures.put(name, texture);
    }
};

const InputManager = struct {
    left_key: bool = false,
    up_key: bool = false,
    right_key: bool = false,
    down_key: bool = false,
    s_key: bool = false,

    pub fn capture_input(self: *InputManager) void {
        self.left_key = rl.isKeyDown(rl.KeyboardKey.left);
        self.up_key = rl.isKeyDown(rl.KeyboardKey.up);
        self.right_key = rl.isKeyDown(rl.KeyboardKey.right);
        self.down_key = rl.isKeyDown(rl.KeyboardKey.down);
        self.s_key = rl.isKeyDown(rl.KeyboardKey.s);
    }
};

fn draw_map() void {
    const grid_size: i32 = 10;
    for (0..(screen_height / grid_size)) |idx| {
        const i: i32 = @intCast(idx);
        rl.drawRectangleLines(
            0,
            grid_size * i,
            screen_width,
            grid_size,
            rl.Color.red,
        );
    }
    for (0..(screen_width / grid_size)) |idx| {
        const i: i32 = @intCast(idx);
        rl.drawRectangleLines(
            grid_size * i,
            0,
            grid_size,
            screen_height,
            rl.Color.red,
        );
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //Initialization
    const configflags: rl.ConfigFlags = .{ .vsync_hint = true };
    rl.setConfigFlags(configflags);
    rl.initWindow(
        screen_width,
        screen_height,
        "raylib [textures] example - image loading",
    );
    defer rl.closeWindow();

    var accumulator: f64 = 0.0;
    var world = World.init(allocator);
    try world.resource_manager.load_texture("resources/tank-texture.png", "tank");
    world.start();
    defer world.deinit();
    const tank = Tank{ .world = &world, .sprite = Sprite{
        .texture = "tank",
        .source = .{
            .x = 801,
            .y = 163,
            .width = 30,
            .height = 26,
        },
    }, .transform = .{
        .position = rl.Vector2.init(15, 13),
    } };
    world.player = tank;

    while (!rl.windowShouldClose()) {
        while (world.is_running) {
            world.input_manager.capture_input();
            const new_time: f64 = get_current_time();
            const frame_time: f64 = new_time - world.current_time;
            world.current_time = new_time;
            accumulator += frame_time;

            while (accumulator > FIXED_DT) {
                world.update(FIXED_DT);
                accumulator -= FIXED_DT;
            }

            const alpha = accumulator / FIXED_DT;
            rl.beginDrawing();
            rl.clearBackground(rl.Color.white);
            draw_map();
            world.render(alpha);
            rl.endDrawing();

            // if (world.current_time - world.start_time > 2.0) {
            //     world.is_running = false;
            // }
        }
    }
}
