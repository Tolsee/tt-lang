const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;
const ArrayList = std.ArrayList;

pub const Lexer = struct {
    source: []const u8,
    start_pos: usize,
    curr_pos: usize,
    line: usize,
    allocator: std.mem.Allocator,
    tokens: ArrayList(Token),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        const tokens = ArrayList(Token).init(allocator);
        return Self{
            .source = source,
            .start_pos = 0,
            .curr_pos = 0,
            .line = 1,
            .allocator = allocator,
            .tokens = tokens,
        };
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
    }

    fn isAtEnd(self: *Self) bool {
        return self.curr_pos + 1 >= self.source.len;
    }

    fn advance(self: *Self) u8 {
        const current_char = self.source[self.curr_pos];
        self.curr_pos += 1;
        return current_char;
    }

    fn peek(self: *Self) u8 {
        if (self.isAtEnd()) {
            return 0;
        }

        return self.source[self.curr_pos];
    }

    fn match(self: *Self, char: u8) bool {
        if (self.curr_pos + 1 >= self.source.len) {
            return false;
        }
        if (self.source[self.curr_pos] != char) {
            return false;
        }

        self.curr_pos += 1;
        return true;
    }

    // fn skipWhitespace(self: *Self) void {
    //     while (self.curr_char != 0) {
    //         switch (self.curr_char) {
    //             ' ', '\t' => {
    //                 self.nextChar();
    //             },
    //             else => break,
    //         }
    //     }
    // }

    // fn skipComment(self: *Self) void {
    //     if (self.curr_char == '#') {
    //         while (self.curr_char != 0) {
    //             if (self.curr_char == '\n') {
    //                 self.nextChar();
    //                 break;
    //             }
    //             self.nextChar();
    //         }
    //     }
    // }
    fn addToken(self: *Self, token_type: TokenType, literal: ?[]const u8) !void {
        const token = Token{
            .token_type = token_type,
            .string = self.source[self.start_pos..self.curr_pos],
            .literal = literal,
            .line = self.line,
        };
        token.print();
        try self.tokens.append(token);
    }

    pub fn scanTokens(self: *Self) !ArrayList(Token) {
        while (!self.isAtEnd()) {
            self.start_pos = self.curr_pos;
            try self.scanToken();
        }

        try self.addToken(.EOF, null);

        return self.tokens;
    }

    pub fn scanToken(self: *Self) !void {
        // self.skipWhitespace();
        // self.skipComment();
        const char = self.advance();

        try switch (char) {
            0 => try self.addToken(TokenType.EOF, null),
            '(' => try self.addToken(.LEFT_PAREN, null),
            ')' => try self.addToken(.RIGHT_PAREN, null),
            '{' => try self.addToken(.LEFT_BRACE, null),
            '}' => try self.addToken(.RIGHT_BRACE, null),
            ',' => try self.addToken(.COMMA, null),
            '.' => try self.addToken(.DOT, null),
            '-' => try self.addToken(.MINUS, null),
            '+' => try self.addToken(.PLUS, null),
            ';' => try self.addToken(.SEMICOLON, null),
            '/' => try self.addToken(.SLASH, null),
            '*' => try self.addToken(.STAR, null),
            '!' => try self.addToken(if (self.match('='))
                .BANG_EQUAL
            else
                .BANG, null),
            '=' => try self.addToken(if (self.match('='))
                .EQUAL_EQUAL
            else
                .EQUAL, null),
            '>' => try self.addToken(if (self.match('='))
                .GREATER_EQUAL
            else
                .GREATER, null),
            '<' => try self.addToken(if (self.match('='))
                .LESS_EQUAL
            else
                .LESS, null),
            ' ', '\r', '\t' => {
                // Ignore whitespace.
            },
            '\n' => {
                self.line += 1;
                self.curr_pos += 1;
            },
            // TODO: Complete
            '"' => try self.getString(),
            '0'...'9' => try self.getNumber(),
            'a'...'z', 'A'...'Z' => self.getIdentifier(),
            else => {
                std.debug.print("Unexpected character: '{}'\n", .{char});
                try self.addToken(TokenType.ERROR, "Unexpected character");
            },
        };
    }

    // TODO: complete this
    // fn nextChar(self: *Self) void {
    //     self.curr_pos += 1;
    // }

    fn getString(self: *Self) !void {
        while (self.peek() != 0 and self.peek() != '"' and !self.isAtEnd()) {
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            try self.addToken(TokenType.ERROR, "Unterminated string");
        }

        _ = self.advance(); // Skip closing quote
        try self.addToken(TokenType.STRING, self.source[self.start_pos..self.curr_pos]);
    }

    fn getNumber(self: *Self) !void {
        while (self.peek() != 0 and std.ascii.isDigit(self.peek())) {
            _ = self.advance();
        }

        try self.addToken(TokenType.NUMBER, self.source[self.start_pos..self.curr_pos]);
    }

    fn getIdentifier(self: *Self) !void {
        while (self.peek() != 0 and (std.ascii.isAlphanumeric(self.peek()) or self.peek() == '_')) {
            _ = self.advance();
        }

        try self.addToken(.IDENTIFIER, self.source[self.start_pos..self.curr_pos]);
    }
};

// NOTE: We can do it later?
// We can check if the identifier is reserved keyword later, I think
fn checkIfKeyword(text: []const u8) TokenType {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const checkText = std.ascii.allocUpperString(allocator, text) catch return .IDENT;

    return if (std.mem.eql(u8, checkText, "PRINT")) .PRINT else if (std.mem.eql(u8, checkText, "INPUT")) .INPUT else if (std.mem.eql(u8, checkText, "LET")) .LET else if (std.mem.eql(u8, checkText, "IF")) .IF else if (std.mem.eql(u8, checkText, "THEN")) .THEN else if (std.mem.eql(u8, checkText, "ENDIF")) .ENDIF else if (std.mem.eql(u8, checkText, "WHILE")) .WHILE else if (std.mem.eql(u8, checkText, "REPEAT")) .REPEAT else if (std.mem.eql(u8, checkText, "ENDWHILE")) .ENDWHILE else if (std.mem.eql(u8, checkText, "GOTO")) .GOTO else if (std.mem.eql(u8, checkText, "LABEL")) .LABEL else .IDENT;
}
