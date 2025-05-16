const std = @import("std");
const Sudoku = @import("Sudoku.zig").Sudoku;

pub fn main() !void {
    var sudoku = try Sudoku.parse("000080000823107496000000008948002001075000600601049820080010902000763000510928074");

    _ = try sudoku.solve();
    try sudoku.display();
}
