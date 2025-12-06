const std = @import("std");
const Allocator = std.mem.Allocator;

const FIXED_DT: f64 = 1.0 / 60.0;

pub fn main() !void {
    var accumulator: f64 = 0.0;
    var currentTime: f64 = std.time.milliTimestamp() / 1000.0;
    var is_running: bool = true;
    while (is_running) {
        const newTime: f64 = std.time.milliTimestamp() / 1000.0;
        var frameTime: f64 = newTime - currentTime;
    }
}
