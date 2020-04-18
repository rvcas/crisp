const std = @import("std");

var input: [2048]u8 = undefined;

const Token = union(enum) {
    add,
    sub,
    mul,
    div,
};

fn computeAdd(expr: []u8) !usize {
    var sum: usize = 0;

    var iter: usize = 0;
    while (iter < expr.len and expr[iter] != ')') : (iter += 1) {
        if (expr[iter] == ' ') {
            continue;
        }

        sum += std.fmt.parseInt(usize, expr[iter .. iter + 1], 10) catch return error.InvalidNumber;
    }

    return sum;
}

fn computeMul(expr: []u8) !usize {
    var product: usize = 1;

    var iter: usize = 0;
    while (iter < expr.len and expr[iter] != ')') : (iter += 1) {
        if (expr[iter] == ' ') {
            continue;
        }

        product *= std.fmt.parseInt(usize, expr[iter .. iter + 1], 10) catch return error.InvalidNumber;
    }

    return product;
}

fn computeDiv(expr: []u8) !usize {
    var iter: usize = 0;
    while (iter < expr.len and expr[iter] == ' ') : (iter += 1) {}

    const m = std.fmt.parseInt(usize, expr[iter .. iter + 1], 10) catch return error.InvalidNumber;

    iter += 1;

    while (iter < expr.len and expr[iter] == ' ') : (iter += 1) {}

    const n = std.fmt.parseInt(usize, expr[iter .. iter + 1], 10) catch return error.InvalidNumber;

    return m / n;
}

fn eval(expr: []u8) !usize {
    var iter: usize = 0;

    if (expr.len == iter or expr[iter] != '(') {
        return error.StartParenNotFound;
    }

    iter += 1;

    var op = expr[iter];

    iter += 1;

    const result = switch (op) {
        '+' => try computeAdd(expr[iter..]),
        '*' => try computeMul(expr[iter..]),
        '/' => try computeDiv(expr[iter..]),
        else => return error.UnknownOp,
    };

    return result;
}

pub fn main() anyerror!void {
    std.debug.warn("Crisp Version 0.0.1 🚀\n", .{});
    std.debug.warn("Press Crtl+c to Exit\n\n", .{});

    const stdout = std.io.getStdOut().outStream();
    const stdin = std.io.getStdIn().inStream();

    while (true) : (input = undefined) {
        try stdout.print("crisp> ", .{});

        const chars = try stdin.read(input[0..]);

        if (eval(input[0 .. chars - 1])) |result| {
            try stdout.print("\n-> {}\n\n", .{result});
        } else |err| switch (err) {
            error.StartParenNotFound => try stdout.print("Error: must begin with a '(' \n\n", .{}),
            error.InvalidNumber => try stdout.print("Error: invalid number \n\n", .{}),
            error.UnknownOp => try stdout.print("Error: unknown operation \n\n", .{}),
        }
    }
}
