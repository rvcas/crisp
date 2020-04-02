const std = @import("std");

var input: [2048]u8 = undefined;

pub fn main() anyerror!void {
    std.debug.warn("Crisp Version 0.0.1\n", .{});
    std.debug.warn("Press Crtl+c to Exit\n", .{});

    const stdout = std.io.getStdOut().outStream();
    const stdin = std.io.getStdIn().inStream();

    while (true) : (input = undefined){
        try stdout.print("crisp> ", .{});
        _ = try stdin.read(input[0..]);
        std.debug.warn("No you're a {}\n", .{ input });
    }
}
