const std = @import("std");
const IntegerBitSet = std.bit_set.IntegerBitSet;
const stdout = std.io.getStdOut().writer();

const CandidateBitSet = IntegerBitSet(9);

const Cell = union(enum) {
    Filled: u8,
    Candidate: CandidateBitSet,
};

pub const Sudoku = struct {
    board: [9][9]Cell,

    pub fn parse(input: []const u8) !Sudoku {
        var sudoku: Sudoku = undefined;
        if (input.len < 9 * 9) {
            return error.TooFewBytes;
        }

        for (input, 0..) |value, index| {
            const i: usize = index / 9;
            const j: usize = index % 9;
            switch (value) {
                '1'...'9' => sudoku.board[i][j] = .{ .Filled = @intCast(value - '0') },
                '0' => sudoku.board[i][j] = .{
                    .Candidate = CandidateBitSet.initFull(),
                },
                else => return error.InvalidBytes,
            }
        }
        sudoku.updateAllCandidate();

        return sudoku;
    }

    pub fn display(sudoku: *Sudoku) !void {
        for (sudoku.board, 0..) |line, i| {
            try stdout.print("\n", .{});
            if (i % 3 == 0) {
                try stdout.print("-------------\n", .{});
            }
            for (line, 0..) |cell, j| {
                if (j % 3 == 0) {
                    try stdout.print("|", .{});
                }
                if (cell == .Filled) {
                    try stdout.print("{d}", .{cell.Filled});
                } else {
                    std.debug.print("{d}", .{0});
                }

                if (j == line.len - 1) {
                    try stdout.print("|", .{});
                }
            }
        }
        try stdout.print("\n-------------\n", .{});
    }

    const Pos = struct { i: usize, j: usize };
    fn findMostConstrainedCell(sudoku: *Sudoku) !?Pos {
        var best: ?Pos = null;
        for (sudoku.board, 0..) |line, i| {
            for (line, 0..) |cell, j| {
                switch (cell) {
                    .Candidate => |candidate| {
                        const count = candidate.count();
                        if (count == 0) {
                            return error.NoCandidate;
                        }
                        if (count == 1) {
                            return .{
                                .i = i,
                                .j = j,
                            };
                        }
                        if (best == null or count < sudoku.board[best.?.i][best.?.j].Candidate.count()) {
                            best = .{
                                .i = i,
                                .j = j,
                            };
                        }
                    },
                    else => continue,
                }
            }
        }
        return best;
    }

    fn getSeenByCell(i: usize, j: usize) [9 + 9 + 9][2]usize {
        const box_i = (i / 3) * 3;
        const box_j = (j / 3) * 3;

        return [9 + 9 + 9][2]usize{
            .{ i, 0 },
            .{ i, 1 },
            .{ i, 2 },
            .{ i, 3 },
            .{ i, 4 },
            .{ i, 5 },
            .{ i, 6 },
            .{ i, 7 },
            .{ i, 8 },
            .{ 0, j },
            .{ 1, j },
            .{ 2, j },
            .{ 3, j },
            .{ 4, j },
            .{ 5, j },
            .{ 6, j },
            .{ 7, j },
            .{ 8, j },
            .{ box_i, box_j },
            .{ box_i, box_j + 1 },
            .{ box_i, box_j + 2 },
            .{ box_i + 1, box_j },
            .{ box_i + 1, box_j + 1 },
            .{ box_i + 1, box_j + 2 },
            .{ box_i + 2, box_j },
            .{ box_i + 2, box_j + 1 },
            .{ box_i + 2, box_j + 2 },
        };
    }

    fn findCandidates(sudoku: *Sudoku, i: usize, j: usize) ?u9 {
        if (sudoku.board[i][j] == .Filled) {
            return null;
        }
        const pos_list = getSeenByCell(i, j);
        var candidate = CandidateBitSet.initFull();
        for (pos_list) |pos| {
            const cell = sudoku.board[pos[0]][pos[1]];
            if (cell == .Filled) {
                candidate.unset(cell.Filled - 1);
            }
        }
        return candidate.mask;
    }

    fn removeCandidateFromSeenCell(sudoku: *Sudoku, value: u8, i: usize, j: usize) void {
        const pos_list = getSeenByCell(i, j);
        for (pos_list) |pos| {
            if (sudoku.board[pos[0]][pos[1]] == .Candidate) {
                sudoku.board[pos[0]][pos[1]].Candidate.unset(value - 1);
            }
        }
    }

    fn updateAllCandidate(sudoku: *Sudoku) void {
        for (&sudoku.board, 0..) |*line, i| {
            for (line, 0..) |*cell, j| {
                if (cell.* == .Candidate) {
                    cell.*.Candidate.mask = sudoku.findCandidates(i, j).?;
                }
            }
        }
    }

    pub fn solve(sudoku: *Sudoku) !void {
        while (try sudoku.findMostConstrainedCell()) |cell| {
            const current_cell = &sudoku.board[cell.i][cell.j];
            if (current_cell.*.Candidate.count() == 1) {
                current_cell.* = .{ .Filled = std.math.log2_int(u9, current_cell.*.Candidate.mask) + 1 };
                sudoku.removeCandidateFromSeenCell(current_cell.*.Filled, cell.i, cell.j);
            } else {
                try stdout.print("Can't solve!\n", .{});
                break;
            }
        }
    }
};
