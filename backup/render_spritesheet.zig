const rl = @import("raylib");
const Color = rl.Color;
const screenWidth = 800;
const screenHeight = 450;
const ss = @import("spritesheet.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

//--------------------------------------------------------------------------------------
// Program entry point
//--------------------------------------------------------------------------------------
pub fn main() anyerror!void {
    //Initialization
    //--------------------------------------------------------------------------------------
    rl.initWindow(
        screenWidth,
        screenHeight,
        "raylib [textures] example - image loading",
    );

    const image = try rl.loadImage("resources/BearSprites.png"); // Loaded in CPU memory (RAM)
    const texture = try rl.loadTextureFromImage(image); // Image converted to texture, GPU memory (VRAM)
    rl.unloadImage(image);

    defer rl.closeWindow();
    defer rl.unloadTexture(texture);

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var ls = try ss.load_spritesheet(allocator, "resources/BearSprites.json");
    defer ls.deinit(allocator);

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    // 293:122:334:100

    const start: usize = @intFromFloat(rl.getTime() * 1000);
    while (!rl.windowShouldClose()) {
        // var sprite = undefined;
        const current: usize = @intFromFloat(rl.getTime() * 1000);
        const timelasp: usize = current - start;
        const sprite_index = (timelasp / 500) % ls.items.len;
        const sprite = ls.items[sprite_index];

        rl.beginDrawing();
        rl.clearBackground(Color.white);
        rl.drawTextureRec(
            texture,
            // .{ .x = 100, .y = 293, .width = 23, .height = 42 },
            .{ .x = sprite.x, .y = sprite.y, .width = sprite.width, .height = sprite.height },
            .{ .x = 200, .y = 200 },
            Color.white,
        );
        rl.drawText(
            "this IS a texture loaded from an image!",
            300,
            370,
            10,
            Color.gray,
        );
        rl.endDrawing();
    }
}
