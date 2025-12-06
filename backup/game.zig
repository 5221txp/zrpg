const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const rand = std.crypto.random;
const time = std.time;
const sleep = std.Thread.sleep;

const FIXED_DT: f64 = 1.0 / 60.0;

fn get_current_time() f64 {
    return @as(f64, @floatFromInt(time.milliTimestamp())) / 1000.0;
}

const Transform = struct {
    x: i32,
    y: i32,
    rotation: f32 = 0,
    sx: f32 = 1.0,
    sy: f32 = 1.0,
};

const World = struct {
    is_running: bool,
    start_time: f64 = 0,
    current_time: f64 = 0,
    resource_manager: ResourceManager,
    input_manager: InputManager,

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

    pub fn update(self: *const World, dt: f64) void {
        _ = self;
        print("Update with dt {d}\n", .{dt});
    }

    pub fn render(self: *const World, alpha: f64) void {
        _ = self;
        print("Render with alpha {d}\n", .{alpha});
        sleep(rand.intRangeAtMost(u64, 10, 20) * 1_000_000);
    }
};

const ResourceManager = struct {
    textures: std.AutoHashMap([]const u8, rl.Texture2D),

    pub fn init(allocator: Allocator) ResourceManager {
        return .{
            .textures = std.AutoHashMap([]const u8, rl.Texture2D).init(allocator),
        };
    }

    pub fn deinit(self: *ResourceManager) void {
        var txt_iter = self.textures.valueIterator();
        while (txt_iter.next()) |txt| {
            rl.unloadTexture(txt.*);
        }
        self.textures.deinit();
    }

    pub fn load_texture(self: *const ResourceManager, imgpath: []const u8, name: []const u8) void {
        const image = try rl.loadImage(imgpath);
        const texture = try rl.loadTextureFromImage(image);
        rl.unloadImage(image);
        self.textures.put(name, texture);
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

    var accumulator: f64 = 0.0;
    var world = World.init(allocator);
    world.start();
    defer world.deinit();
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
        world.render(alpha);
        if (world.current_time - world.start_time > 2.0) {
            world.is_running = false;
        }
    }
}
