const rl = @import("raylib");
const Color = rl.Color;
const screenWidth = 1200;
const screenHeight = 800;
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

    const image = try rl.loadImage("resources/characters2.png"); // Loaded in CPU memory (RAM)
    const texture = try rl.loadTextureFromImage(image); // Image converted to texture, GPU memory (VRAM)
    rl.unloadImage(image);

    defer rl.closeWindow();
    defer rl.unloadTexture(texture);

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var ls = try ss.load_spritesheet(allocator, "resources/characters2.json");
    defer ls.deinit(allocator);

    while (!rl.windowShouldClose()) {
        // var sprite = undefined;
        const offset_x: i32 = 50;
        const offset_y: i32 = 50;

        rl.beginDrawing();
        rl.clearBackground(Color.white);
        // rl.drawTextureRec(
        //     texture,
        //     // .{ .x = 100, .y = 293, .width = 23, .height = 42 },
        //     .{ .x = sprite.x, .y = sprite.y, .width = sprite.width, .height = sprite.height },
        //     .{ .x = 200, .y = 200 },
        //     Color.white,
        // );
        rl.drawTexture(
            texture,
            offset_x,
            offset_y,
            Color.white,
        );
        for (ls.items) |s| {
            rl.drawRectangleLines(
                s.int_x() + offset_x,
                s.int_y() + offset_y,
                s.int_width(),
                s.int_height(),
                Color.red,
            );
        }
        rl.drawText(
            "this IS a texture loaded from an image!",
            10,
            10,
            10,
            Color.gray,
        );
        rl.endDrawing();
    }
}
