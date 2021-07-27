const std = @import("std");
const terminal = @import("zig-terminal");

const ArrayList = std.ArrayList;

const Op = enum {
    add,
    subtract,
    multiply,
    divide,
};

const Token = union(enum) {
    paren: u8,
    op: Op,
    number: []u8,
};

fn tokenize(src: []u8, allocator: *std.mem.Allocator) ![]Token {
    var tokens = ArrayList(Token).init(allocator);
    errdefer tokens.deinit();

    var iter: usize = 0;

    while (iter < src.len) {
        const ch = src[iter];

        iter += 1;

        switch (ch) {
            '(', ')' => try tokens.append(.{ .paren = ch }),
            '+' => try tokens.append(.{ .op = .add }),
            '-' => try tokens.append(.{ .op = .subtract }),
            '*' => try tokens.append(.{ .op = .multiply }),
            '/' => try tokens.append(.{ .op = .divide }),
            '0'...'9' => {
                var value = ArrayList(u8).init(allocator);
                errdefer value.deinit();

                try value.append(ch);

                while (iter < src.len) {
                    const next = src[iter];

                    switch (next) {
                        '0'...'9' => {
                            iter += 1;

                            try value.append(next);
                        },
                        else => break,
                    }
                }

                try tokens.append(.{ .number = value.items });
            },
            ' ' => {},
            else => return error.InvalidCharacter,
        }
    }

    return tokens.items;
}

const ComputeError = error{
    BadInput,
    InvalidNumber,
    NotImplemented,
    ExpectedOp,
    OutOfMemory,
    BadDivisionParams,
    BadSubtractionParams,
};

fn compute(tokens: []Token, iter: *usize, allocator: *std.mem.Allocator) ComputeError!usize {
    if (iter.* >= tokens.len) {
        return error.BadInput;
    }

    const token = tokens[iter.*];

    iter.* += 1;

    switch (token) {
        .number => |num| {
            const n = std.fmt.parseInt(usize, num, 10) catch return error.InvalidNumber;

            return n;
        },
        .paren => |paren| {
            if (paren == '(') {
                const next = tokens[iter.*];

                iter.* += 1;

                switch (next) {
                    .op => |op| switch (op) {
                        .add => {
                            var sum: usize = 0;

                            while (iter.* < tokens.len) {
                                const second_next = tokens[iter.*];

                                switch (second_next) {
                                    .paren => |subparen| {
                                        if (subparen == ')') {
                                            break;
                                        }

                                        sum += try compute(tokens, iter, allocator);
                                    },
                                    else => {
                                        sum += try compute(tokens, iter, allocator);
                                    },
                                }
                            }

                            iter.* += 1;

                            return sum;
                        },
                        .multiply => {
                            var product: usize = 1;

                            while (iter.* < tokens.len) {
                                const second_next = tokens[iter.*];

                                switch (second_next) {
                                    .paren => |subparen| {
                                        if (subparen == ')') {
                                            break;
                                        }

                                        product *= try compute(tokens, iter, allocator);
                                    },
                                    else => {
                                        product *= try compute(tokens, iter, allocator);
                                    },
                                }
                            }

                            iter.* += 1;

                            return product;
                        },
                        .divide => {
                            var params = ArrayList(usize).init(allocator);
                            errdefer params.deinit();

                            while (iter.* < tokens.len) {
                                const second_next = tokens[iter.*];

                                switch (second_next) {
                                    .paren => |subparen| {
                                        if (subparen == ')') {
                                            break;
                                        }

                                        const result = try compute(tokens, iter, allocator);

                                        try params.append(result);
                                    },
                                    else => {
                                        const result = try compute(tokens, iter, allocator);

                                        try params.append(result);
                                    },
                                }
                            }

                            iter.* += 1;

                            const items = params.items;

                            if (items.len != 2) {
                                return error.BadDivisionParams;
                            }

                            return items[0] / items[1];
                        },
                        .subtract => {
                            var params = ArrayList(usize).init(allocator);
                            errdefer params.deinit();

                            while (iter.* < tokens.len) {
                                const second_next = tokens[iter.*];

                                switch (second_next) {
                                    .paren => |subparen| {
                                        if (subparen == ')') {
                                            break;
                                        }

                                        const result = try compute(tokens, iter, allocator);

                                        try params.append(result);
                                    },
                                    else => {
                                        const result = try compute(tokens, iter, allocator);

                                        try params.append(result);
                                    },
                                }
                            }

                            iter.* += 1;

                            const items = params.items;

                            if (items.len != 2) {
                                return error.BadSubtractionParams;
                            }

                            return items[0] - items[1];
                        },
                    },
                    else => return error.ExpectedOp,
                }
            }

            return error.BadInput;
        },
        else => return error.BadInput,
    }
}

fn eval(expr: []u8) !usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var tokens = try tokenize(expr, &arena.allocator);

    var iter: usize = 0;

    const result = try compute(tokens, &iter, &arena.allocator);

    return result;
}

pub fn main() anyerror!void {
    var term = terminal.Terminal.init();

    try term.printWithAttributes(.{
        .blue,
        "Crisp Version 0.0.1 🚀\n",
        "Type :q to Exit\n\n",
        .reset,
    });

    while (true) {
        try term.printWithAttributes(.{
            terminal.TextAttributes{
                .foreground = .magenta,
                .bold = true,
            },
            "crisp> ",
            terminal.TextAttributes{
                .foreground = .cyan,
                .bold = true,
            },
        });

        const chars = try term.reader().readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            std.math.maxInt(usize),
        );
        defer std.heap.page_allocator.free(chars);

        try term.resetAttributes();

        if (std.mem.eql(u8, chars, ":q")) {
            try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .green,
                    .bold = true,
                },
                "\nGoodbye 👋\n",
                .reset,
            });

            std.process.exit(0);
        }

        if (eval(chars)) |result| {
            try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .green,
                    .bold = true,
                },
                terminal.format("\n-> {}\n\n", .{result}),
                .reset,
            });
        } else |err| switch (err) {
            error.OutOfMemory => try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .red,
                    .bold = true,
                },
                "Error: out of memory \n\n",
                .reset,
            }),
            error.InvalidCharacter => try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .red,
                    .bold = true,
                },
                "Error: invalid character \n\n",
                .reset,
            }),
            error.DivisionByZero => try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .red,
                    .bold = true,
                },
                "Error: canot divide by zero \n\n",
                .reset,
            }),
            else => try term.printWithAttributes(.{
                terminal.TextAttributes{
                    .foreground = .red,
                    .bold = true,
                },
                "Error: error calculating result \n\n",
                .reset,
            }),
        }
    }
}
