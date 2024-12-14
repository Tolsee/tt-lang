const std = @import("std");
const compiler = @import("compiler.zig");

pub fn main() !void {
    const source = "IFTHENMINUS+-123 foo*THEN/";
    var c = compiler.Compiler.init(source, "out.c");

    try c.compile();
}

test "parser test" {
    const source = "PRINT \"Hello, World!\"\n";
    var c = compiler.Compiler.init(source, "out.c");

    try c.compile();
}

test "fibonacci program test" {
    const source =
        "PRINT \"How many fibonacci numbers do you want?\"\n" ++
        "INPUT nums\n" ++
        "PRINT \"\"\n" ++
        "LET a = 0\n" ++
        "LET b = 1\n" ++
        "WHILE nums > 0 REPEAT\n" ++
        "    PRINT a\n" ++
        "    LET c = a + b\n" ++
        "    LET a = b\n" ++
        "    LET b = c\n" ++
        "    LET nums = nums - 1\n" ++
        "ENDWHILE\n";
    var c = compiler.Compiler.init(source, "out.c");

    try c.compile();
}

test "all language grammar test" {
    const source =
        "PRINT \"Hello\"\n" ++
        "INPUT x\n" ++
        "LET y = 10\n" ++
        "IF x == y THEN\n" ++
        "    PRINT \"Equal\"\n" ++
        "ENDIF\n" ++
        "WHILE x < y REPEAT\n" ++
        "    PRINT x\n" ++
        "    LET x = x + 1\n" ++
        "ENDWHILE\n";
    var c = compiler.Compiler.init(source, "out.c");

    try c.compile();
}
