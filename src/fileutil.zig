const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn read_text_file(allocator: Allocator, filepath: []const u8) ![]u8 {
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
