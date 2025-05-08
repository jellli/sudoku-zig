const std = @import("std");

pub const Sudoku = struct {
    board: [9][9]u8,

    pub fn parse(input: []const u8) !Sudoku {
        var sudoku: Sudoku = undefined;
        if (input.len < 9 * 9) {
            return error.TooFewBytes;
        }

        for (input, 0..) |value, index| switch (value) {
            '0'...'9' => {
                const i: usize = index / 9;
                const j: usize = index % 9;
                sudoku.board[i][j] = value - '0';
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

    pub fn findCandidates(sudoku: *Sudoku, i: usize, j: usize) ?u9 {
        if (sudoku.board[i][j] != 0) {
            return null;
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
        var mask: u9 = 0b000000000;
        for (values, 0..) |value, index| {
            if (value == 0 or std.mem.indexOfScalar(u8, &values, value) != index) {
                continue;
            }
            mask += (@as(u9, 1) << @intCast(value - 1));
        }
        return ~mask;
    }

    // fn solve(sudoku: *Sudoku) []const u8 {
    //     const candidates: [9][9]u9 = undefined;
    // }
};
