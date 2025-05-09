const std = @import("std");
const Sudoku = @import("Sudoku.zig").Sudoku;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var sudoku = try Sudoku.parse("001700509573024106800501002700295018009400305652800007465080071000159004908007053");
    std.debug.print("input:", .{});
    try sudoku.display();

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    _ = try sudoku.solve();

    const end = timer.read();
    const elapsed_ns = end - start;
    std.debug.print("cost: {d:.3} ms\n", .{@as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0});
}
