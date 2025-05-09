const std = @import("std");
const Sudoku = @import("Sudoku.zig").Sudoku;

pub fn main() !void {
    var sudoku = try Sudoku.parse("000080000823107496000000008948002001075000600601049820080010902000763000510928074");
    std.debug.print("input:", .{});
    try sudoku.display();

    var timer = try std.time.Timer.start();
    const start = timer.lap();

    _ = try sudoku.solve();

    const end = timer.read();
    const elapsed_ns = end - start;
    std.debug.print("cost: {d:.3} ms\n", .{@as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0});

    try sudoku.display();
}
