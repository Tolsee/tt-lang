const std = @import("std");
const TokenType = @import("TokenType.zig").TokenType;

pub const Token = struct {
    token_type: TokenType,
    string: []const u8,
    // TODO: Support all types of literals
    literal: ?[]const u8,
    line: usize,

    pub fn print(self: Token) void {
        std.debug.print("{s} {?s}\n", .{ self.string, self.literal });
    }
};
