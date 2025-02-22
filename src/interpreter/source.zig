const std = @import("std");
const stdout = std.io.getStdOut().writer();
const lexer = @import("../lexer.zig");

pub fn run(allocator: std.mem.Allocator, path: []u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // var buffered = std.io.bufferedReader(file);
    // var buffReader = buffered.reader();
    const reader = file.reader();
    var buffer: [1000]u8 = undefined;
    @memset(buffer[0..], 0);

    _ = try reader.readUntilDelimiterOrEof(buffer[0..], '\n');
    var x = lexer.Lexer.init(allocator, buffer[0..]);
    defer x.deinit();
    _ = try x.scanTokens();

    // try stdout.print("{s}\n", .{buffer});
}
