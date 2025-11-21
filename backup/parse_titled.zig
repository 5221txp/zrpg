const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const tiled = @import("tiled.zig");

fn read_text_file(allocator: Allocator, filepath: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });
    defer file.close();

    const fileSize = try file.getEndPos();
    const buffer = try allocator.alloc(u8, fileSize);

    const readBytes = try file.readAll(buffer);
    if (readBytes != fileSize) {
        return error.UnexpectedEOF;
    }

    return buffer;
}

// pub const Map = struct { width: i32, height: i32, tilewidth: i32, tileheight: i32, infinite: bool };

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    var allocator: std.mem.Allocator = gpa.allocator();
    defer gpa.deinit();

    const content = try read_text_file(allocator, "resources/tiled/map.json");
    defer allocator.free(content);
    std.debug.print("{s}\n", .{content});
    const map_parsed = try std.json.parseFromSlice(tiled.Map, allocator, content, .{});
    defer map_parsed.deinit();
    const map = map_parsed.value;
    if (map.properties) |pts|
        std.debug.print(">>>>>>> {s}\n", .{pts[0].type});
}
