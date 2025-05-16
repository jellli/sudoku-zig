const std = @import("std");
const Sudoku = @import("Sudoku.zig").Sudoku;

pub fn main() !void {
    var buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var sudoku = try Sudoku.parse(args[1]);
    var timer = try std.time.Timer.start();
    const start = timer.lap();

    _ = try sudoku.solve();

    const end = timer.read();
    const elapsed_ns = end - start;

    try sudoku.display();
    std.debug.print("cost: {d:.3} ms\n", .{@as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0});
}
