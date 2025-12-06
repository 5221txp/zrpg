const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const rand = std.crypto.random;
const time = std.time;
const sleep = std.Thread.sleep;
const screenWidth = 1200;
const screenHeight = 800;

const FIXED_DT: f64 = 1.0 / 30.0;

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
    tranform: Transform,
    prev_transform: ?Transform = null,
    direction: Direction = .up,
    velocity: f32 = 10,

    pub fn update(self: *Tank, dt: f64) void {
        if (self.world.new_render) {
            self.prev_transform = self.tranform.copy();
        }
        if (self.world.input_manager.left_key) {
            self.direction = .left;
            self.tranform.rotation = 180;
            self.tranform.position.x -= self.velocity;
        }
        if (self.world.input_manager.right_key) {
            self.direction = .right;
            self.tranform.rotation = 0;
            self.tranform.position.x += self.velocity;
        }
        if (self.world.input_manager.up_key) {
            self.direction = .up;
            self.tranform.rotation = 270;
            self.tranform.position.y -= self.velocity;
        }
        if (self.world.input_manager.down_key) {
            self.direction = .left;
            self.tranform.rotation = 90;
            self.tranform.position.y += self.velocity;
        }
        print("Update tank with dt {d}\n", .{dt});
    }

    pub fn render(self: *Tank, alpha: f64) void {
        print("Render tank with alpha {d}\n", .{alpha});
        rl.drawTexturePro(
            self.world.resource_manager.textures.get(self.sprite.texture).?,
            self.sprite.source,
            rl.Rectangle{
                .x = self.tranform.position.x,
                .y = self.tranform.position.y,
                .width = self.sprite.source.width,
                .height = self.sprite.source.height,
            },
            rl.Vector2.init(
                self.sprite.source.width / 2,
                self.sprite.source.height / 2,
            ),
            self.tranform.rotation,
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
    new_render: bool = false,

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
        if (self.new_render) {
            self.new_render = false;
        }
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

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //Initialization
    rl.initWindow(
        screenWidth,
        screenHeight,
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
    }, .tranform = .{
        .position = rl.Vector2.init(100, 200),
    } };
    world.player = tank;

    while (!rl.windowShouldClose()) {
        while (world.is_running) {
            world.input_manager.capture_input();
            const new_time: f64 = get_current_time();
            const frame_time: f64 = new_time - world.current_time;
            world.current_time = new_time;
            accumulator += frame_time;

            world.new_render = true;
            while (accumulator > FIXED_DT) {
                world.update(FIXED_DT);
                accumulator -= FIXED_DT;
            }

            const alpha = accumulator / FIXED_DT;
            rl.beginDrawing();
            rl.clearBackground(rl.Color.white);
            world.render(alpha);
            rl.endDrawing();

            // if (world.current_time - world.start_time > 2.0) {
            //     world.is_running = false;
            // }
        }
    }
}
