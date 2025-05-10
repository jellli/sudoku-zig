const std = @import("std");
const IntegerBitSet = std.bit_set.IntegerBitSet;

const CandidateSet = IntegerBitSet(9);
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

    pub fn findMostConstrainedCell(sudoku: *Sudoku) !?CandidatePos {
        var candidate: ?CandidateSet = null;
        var i_pos: ?u4 = null;
        var j_pos: ?u4 = null;
        for (sudoku.candidates, 0..) |line, i| {
            for (line, 0..) |cell, j| {
                if (sudoku.board[i][j] != 0) {
                    continue;
                }
                if (cell.count() == 0) {
                    return error.NoCandidate;
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

    pub fn getSeenByCell(i: usize, j: usize) [9 + 9 + 9][2]usize {
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

    pub fn findCandidates(sudoku: *Sudoku, i: usize, j: usize) ?u9 {
        if (sudoku.board[i][j] != 0) {
            return null;
        }
        const pos_list = getSeenByCell(i, j);
        var values: [9 + 9 + 9]u8 = undefined;
        for (pos_list, 0..) |pos, index| {
            values[index] = sudoku.board[pos[0]][pos[1]];
        }
        var mask: u9 = 0;
        for (values, 0..) |value, index| {
            if (value == 0 or std.mem.indexOfScalar(u8, &values, value) != index) {
                continue;
            }
            mask += @as(u9, 1) << @intCast(value - 1);
        }
        return ~mask;
    }

    fn updateSeenCandidate(sudoku: *Sudoku, i: u4, j: u4) void {
        const pos_list = getSeenByCell(i, j);
        for (pos_list) |pos| {
            if (sudoku.board[pos[0]][pos[1]] == 0) {
                sudoku.candidates[pos[0]][pos[1]].mask = sudoku.findCandidates(pos[0], pos[1]).?;
            }
        }
    }

    fn updateAllCandidate(sudoku: *Sudoku) void {
        for (&sudoku.candidates, 0..) |*line, i| {
            for (line, 0..) |*cell, j| {
                if (sudoku.board[i][j] == 0) {
                    cell.*.mask = sudoku.findCandidates(i, j).?;
                }
            }
        }
    }

    pub fn solve(sudoku: *Sudoku) ![]const u8 {
        sudoku.updateAllCandidate();
        while (try sudoku.findMostConstrainedCell()) |res| {
            if (res.candidate.count() == 1) {
                sudoku.board[res.i][res.j] = std.math.log2_int(u9, res.candidate.mask) + 1;
                sudoku.updateSeenCandidate(res.i, res.j);
            } else {
                // TODO: resolve multi candidates
                break;
            }
        }
        return "ans";
    }
};
