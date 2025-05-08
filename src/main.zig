const std = @import("std");
const Sudoku = @import("Sudoku.zig").Sudoku;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var sudoku = try Sudoku.parse("001700509573024106800501002700295018009400305652800007465080071000159004908007053");
    try sudoku.display();

    const i: usize = try std.fmt.parseInt(usize, args[1], 10);
    const j: usize = try std.fmt.parseInt(usize, args[2], 10);

    std.debug.print("({d},{d}):{b:0>9}\n", .{ i, j, sudoku.findCandidates(i, j).? });
}
