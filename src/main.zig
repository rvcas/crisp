const std = @import("std");

const ArrayList = std.ArrayList;

var input: [2048]u8 = undefined;

const Op = enum {
    add,
    subtract,
    multiple,
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
            '*' => try tokens.append(.{ .op = .multiple }),
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
                        .multiple => {
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
    std.debug.print("\u{001b}[36mCrisp Version 0.0.1 🚀\n", .{});
    std.debug.print("\u{001b}[36mType :q to Exit\n\n", .{});

    const stdout = std.io.getStdOut().outStream();
    const stdin = std.io.getStdIn().inStream();

    while (true) : (input = undefined) {
        try stdout.print("\u{001b}[31;1mcrisp> \u{001b}[36m", .{});

        const chars = try stdin.read(input[0..]);

        if (std.mem.eql(u8, input[0 .. chars - 1], ":q")) {
            try stdout.print("\n\u{001b}[1;32mGoodbye 👋\n\n", .{});

            std.process.exit(0);
        }

        if (eval(input[0 .. chars - 1])) |result| {
            try stdout.print("\n\u{001b}[1;32m-> {}\n\n", .{result});
        } else |err| switch (err) {
            error.OutOfMemory => try stdout.print("Error: out of memory \n\n", .{}),
            error.InvalidCharacter => try stdout.print("Error: invalid character \n\n", .{}),
            else => try stdout.print("Error: error calculating result \n\n", .{}),
        }
    }
}
