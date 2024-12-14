const std = @import("std");
const compiler = @import("compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leak detected!");
    }
    const allocator = gpa.allocator();

    const source = "PRINT \"Hello, World!\"\n";
    var c = compiler.Compiler.init(allocator, source, "out.c");
    try c.compile();
}

test "parser test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const source = "PRINT \"Hello, World!\"\n";
    var c = compiler.Compiler.init(allocator, source, "out.c");
    try c.compile();
}

test "fibonacci program test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const source =
        \\PRINT "How many fibonacci numbers do you want?"
        \\INPUT nums
        \\PRINT ""
        \\LET a = 0
        \\LET b = 1
        \\WHILE nums > 0 REPEAT
        \\    PRINT a
        \\    LET c = a + b
        \\    LET a = b
        \\    LET b = c
        \\    LET nums = nums - 1
        \\ENDWHILE
    ;
    var c = compiler.Compiler.init(allocator, source, "out.c");
    try c.compile();
}

test "all language grammar test" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const source =
        \\PRINT "Hello"
        \\INPUT x
        \\LET y = 10
        \\IF x == y THEN
        \\    PRINT "Equal"
        \\ENDIF
        \\WHILE x < y REPEAT
        \\    PRINT x
        \\    LET x = x + 1
        \\ENDWHILE
    ;
    var c = compiler.Compiler.init(allocator, source, "out.c");
    try c.compile();
}
