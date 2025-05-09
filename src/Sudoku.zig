const std = @import("std");
const IntegerBitSet = std.bit_set.IntegerBitSet;

const FILLED_CANDIDATE = 0b0000000001;
const CandidateSet = IntegerBitSet(10);
const CandidatePos = struct {
    candidate: CandidateSet,
    i: u4,
    j: u4,
};

pub const Sudoku = struct {
    board: [9][9]u4,
    candidates: [9][9]CandidateSet,

    pub fn parse(input: []const u8) !Sudoku {
        var sudoku: Sudoku = undefined;
        if (input.len < 9 * 9) {
            return error.TooFewBytes;
        }

        for (input, 0..) |value, index| switch (value) {
            '0'...'9' => {
                const i: usize = index / 9;
                const j: usize = index % 9;
                sudoku.board[i][j] = @intCast(value - '0');
            },
            else => return error.InvalidBytes,
        };

        return sudoku;
    }

    pub fn display(sudoku: *Sudoku) !void {
        const writer = std.io.getStdOut().writer();
        for (sudoku.board, 0..) |line, i| {
            try writer.print("\n", .{});
            if (i % 3 == 0) {
                try writer.print("-------------\n", .{});
            }
            for (line, 0..) |cell, j| {
                if (j % 3 == 0) {
                    try writer.print("|", .{});
                }

                try writer.print("{any}", .{cell});

                if (j == line.len - 1) {
                    try writer.print("|", .{});
                }
            }
        }
        try writer.print("\n-------------\n", .{});
    }

    pub fn findMostConstrainedCell(sudoku: *Sudoku) ?CandidatePos {
        var candidate: ?CandidateSet = null;
        var i_pos: ?u4 = null;
        var j_pos: ?u4 = null;
        for (sudoku.candidates, 0..) |line, i| {
            for (line, 0..) |cell, j| {
                if (cell.isSet(0)) {
                    continue;
                }
                if (cell.count() == 1) {
                    return .{
                        .candidate = cell,
                        .i = @truncate(i),
                        .j = @truncate(j),
                    };
                }
                if (candidate) |nn_candidate| {
                    if (cell.count() < nn_candidate.count()) {
                        candidate = cell;
                        i_pos = @truncate(i);
                        j_pos = @truncate(j);
                    }
                } else {
                    candidate = cell;
                    i_pos = @truncate(i);
                    j_pos = @truncate(j);
                }
            }
        }
        if (candidate == null) {
            return null;
        }
        return .{ .candidate = candidate.?, .i = i_pos.?, .j = j_pos.? };
    }

    pub fn findCandidates(sudoku: *Sudoku, i: usize, j: usize) u10 {
        if (sudoku.board[i][j] != 0) {
            return FILLED_CANDIDATE;
        }
        const box_i = (i / 3) * 3;
        const box_j = (j / 3) * 3;
        const values = [9 + 9 + 9]u8{
            // Rows
            sudoku.board[i][0],
            sudoku.board[i][1],
            sudoku.board[i][2],
            sudoku.board[i][3],
            sudoku.board[i][4],
            sudoku.board[i][5],
            sudoku.board[i][6],
            sudoku.board[i][7],
            sudoku.board[i][8],
            // Columns
            sudoku.board[0][j],
            sudoku.board[1][j],
            sudoku.board[2][j],
            sudoku.board[3][j],
            sudoku.board[4][j],
            sudoku.board[5][j],
            sudoku.board[6][j],
            sudoku.board[7][j],
            sudoku.board[8][j],
            // Box
            sudoku.board[box_i][box_j],
            sudoku.board[box_i][box_j + 1],
            sudoku.board[box_i][box_j + 2],

            sudoku.board[box_i + 1][box_j],
            sudoku.board[box_i + 1][box_j + 1],
            sudoku.board[box_i + 1][box_j + 2],

            sudoku.board[box_i + 2][box_j],
            sudoku.board[box_i + 2][box_j + 1],
            sudoku.board[box_i + 2][box_j + 2],
        };
        var mask: u10 = 0;
        for (values, 0..) |value, index| {
            if (value == 0 or std.mem.indexOfScalar(u8, &values, value) != index) {
                continue;
            }
            mask += @as(u10, 1) << @intCast(value);
        }
        return ~mask;
    }

    fn updateAllCandidate(sudoku: *Sudoku) void {
        for (&sudoku.candidates, 0..) |*line, i| {
            for (line, 0..) |*cell, j| {
                if (!cell.*.isSet(0)) {
                    cell.*.mask = sudoku.findCandidates(i, j);
                    cell.*.unset(0);
                }
            }
        }
    }

    pub fn solve(sudoku: *Sudoku) ![]const u8 {
        sudoku.updateAllCandidate();
        while (sudoku.findMostConstrainedCell()) |res| {
            if (res.candidate.count() == 1) {
                sudoku.board[res.i][res.j] = std.math.log2_int(u10, res.candidate.mask);
                sudoku.candidates[res.i][res.j].set(0);
                sudoku.updateAllCandidate();
            } else {
                // TODO: resolve multi candidates
                break;
            }
        }
        return "ans";
    }
};
