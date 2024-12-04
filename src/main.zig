//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    // const source = "PRINT \"Hello, World!\"\n";
    const source = "IF+-123 foo*THEN/";
    var l = lexer.Lexer.init(source);

    while (true) {
        const token = l.getToken();
        std.debug.print("Token: {s: <10} | Text: {s}\n", .{
            @tagName(token.type),
            token.text,
        });
        if (token.type == .EOF) break;
        // Process token
    }
}
