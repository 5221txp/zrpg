const std = @import("std");
const rl = @import("raylib");

pub fn load_texture(filepath: [:0]const u8) !rl.Texture {
    const image = try rl.loadImage(filepath);
    const texture = try rl.loadTextureFromImage(image);
    rl.unloadImage(image);
    return texture;
}
