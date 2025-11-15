const std = @import("std");
const Allocator = std.mem.Allocator;
const fileutil = @import("fileutil.zig");
const json = std.json;

pub const Sprite = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn int_x(self: Sprite) i32 {
        return @intFromFloat(self.x);
    }

    pub fn int_y(self: Sprite) i32 {
        return @intFromFloat(self.y);
    }

    pub fn int_width(self: Sprite) i32 {
        return @intFromFloat(self.width);
    }

    pub fn int_height(self: Sprite) i32 {
        return @intFromFloat(self.height);
    }
};

pub fn load_spritesheet(allocator: Allocator, filepath: []const u8) !std.ArrayList(Sprite) {
    const file_content = try fileutil.read_text_file(allocator, filepath);
    defer allocator.free(file_content);
    const parsed = try json.parseFromSlice([]Sprite, allocator, file_content, .{});
    defer parsed.deinit();
    var data: std.ArrayList(Sprite) = .empty;
    for (parsed.value) |s| {
        try data.append(allocator, s);
    }
    return data;
}
