const std = @import("std");

pub const TokenType = enum {
    // Special tokens
    EOF,
    NEWLINE,
    ERROR,

    // Commands
    PRINT,
    INPUT,
    LET,
    IF,
    THEN,
    ENDIF,
    WHILE,
    REPEAT,
    ENDWHILE,
    GOTO,
    LABEL,

    // Operators
    EQ,
    PLUS,
    MINUS,
    ASTERISK,
    SLASH,
    EQEQ,
    NOTEQ,
    LT,
    LTEQ,
    GT,
    GTEQ,

    // Structure
    LPAREN,
    RPAREN,

    // Other
    IDENT,
    STRING,
    NUMBER,
};

pub const Token = struct {
    type: TokenType,
    text: []const u8,

    pub fn init(token_type: TokenType, text: []const u8) Token {
        return Token{
            .type = token_type,
            .text = text,
        };
    }
};

pub const Lexer = struct {
    source: []const u8,
    curr_pos: usize,
    curr_char: u8,

    const Self = @This();

    pub fn init(source: []const u8) Self {
        return Self{
            .source = source,
            .curr_pos = 0,
            .curr_char = if (source.len > 0) source[0] else 0,
        };
    }

    fn nextChar(self: *Self) void {
        self.curr_pos += 1;
        if (self.curr_pos >= self.source.len) {
            self.curr_char = 0;
        } else {
            self.curr_char = self.source[self.curr_pos];
        }
    }

    fn peek(self: *Self) u8 {
        if (self.curr_pos + 1 >= self.source.len) {
            return 0;
        }
        return self.source[self.curr_pos + 1];
    }

    fn skipWhitespace(self: *Self) void {
        while (self.curr_char != 0) {
            switch (self.curr_char) {
                ' ', '\t' => {
                    self.nextChar();
                },
                else => break,
            }
        }
    }

    fn skipComment(self: *Self) void {
        if (self.curr_char == '#') {
            while (self.curr_char != 0) {
                if (self.curr_char == '\n') {
                    self.nextChar();
                    break;
                }
                self.nextChar();
            }
        }
    }

    pub fn getToken(self: *Self) Token {
        // Reset curr_char based on position
        if (self.curr_pos < self.source.len) {
            self.curr_char = self.source[self.curr_pos];
        } else {
            self.curr_char = 0;
        }

        self.skipWhitespace();
        self.skipComment();

        const token = switch (self.curr_char) {
            0 => Token.init(.EOF, ""),
            '\n' => blk: {
                self.nextChar();
                break :blk Token.init(.NEWLINE, "\n");
            },
            '+' => blk: {
                self.nextChar();
                break :blk Token.init(.PLUS, "+");
            },
            '-' => blk: {
                self.nextChar();
                break :blk Token.init(.MINUS, "-");
            },
            '*' => blk: {
                self.nextChar();
                break :blk Token.init(.ASTERISK, "*");
            },
            '/' => blk: {
                self.nextChar();
                break :blk Token.init(.SLASH, "/");
            },
            '=' => blk: {
                if (self.peek() == '=') {
                    const lastPos = self.curr_pos;
                    self.nextChar();
                    self.nextChar();
                    break :blk Token.init(.EQEQ, self.source[lastPos..self.curr_pos]);
                }

                self.nextChar();
                break :blk Token.init(.EQ, "=");
            },
            '>' => blk: {
                if (self.peek() == '=') {
                    const lastPos = self.curr_pos;
                    self.nextChar();
                    self.nextChar();
                    break :blk Token.init(.GTEQ, self.source[lastPos..self.curr_pos]);
                }

                self.nextChar();
                break :blk Token.init(.GT, ">");
            },
            '<' => blk: {
                if (self.peek() == '=') {
                    const lastPos = self.curr_pos;
                    self.nextChar();
                    self.nextChar();
                    break :blk Token.init(.LTEQ, self.source[lastPos..self.curr_pos]);
                }

                self.nextChar();
                break :blk Token.init(.LT, "<");
            },
            '!' => blk: {
                if (self.peek() == '=') {
                    const lastPos = self.curr_pos;
                    self.nextChar();
                    self.nextChar();
                    break :blk Token.init(.NOTEQ, self.source[lastPos..self.curr_pos]);
                }

                self.nextChar();
                break :blk Token.init(.ERROR, "Expected !=");
            },
            '"' => self.getString(),
            '0'...'9' => self.getNumber(),
            'a'...'z', 'A'...'Z' => self.getIdentifier(),
            else => blk: {
                self.nextChar();
                break :blk Token.init(.ERROR, "Unknown token");
            },
        };

        std.debug.print("\n\ngetToken END\n", .{});
        std.debug.print("curr_pos: {d}\n", .{self.curr_pos});
        std.debug.print("curr_char: {d}\n", .{self.curr_char});
        std.debug.print("peek: {d}\n", .{self.peek()});

        return token;
    }

    fn getString(self: *Self) Token {
        const startPos = self.curr_pos;
        self.nextChar(); // Skip opening quote

        while (self.curr_char != 0 and self.curr_char != '"') {
            self.nextChar();
        }

        if (self.curr_char == '"') {
            self.nextChar(); // Skip closing quote
            return Token.init(.STRING, self.source[startPos..self.curr_pos]);
        }

        return Token.init(.ERROR, "Unterminated string");
    }

    fn getNumber(self: *Self) Token {
        const startPos = self.curr_pos;

        while (self.curr_char != 0 and std.ascii.isDigit(self.curr_char)) {
            self.nextChar();
        }

        return Token.init(.NUMBER, self.source[startPos..self.curr_pos]);
    }

    fn getIdentifier(self: *Self) Token {
        const startPos = self.curr_pos;

        while (self.curr_char != 0 and (std.ascii.isAlphanumeric(self.curr_char) or self.curr_char == '_')) {
            self.nextChar();
        }

        const text = self.source[startPos..self.curr_pos];
        const tokenType = checkIfKeyword(text);
        std.debug.print("getIdentifier: {s}\n", .{text});
        std.debug.print("curr_pos: {d}\n", .{self.curr_pos});
        return Token.init(tokenType, text);
    }
};

fn checkIfKeyword(text: []const u8) TokenType {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const checkText = std.ascii.allocUpperString(allocator, text) catch return .IDENT;

    return if (std.mem.eql(u8, checkText, "PRINT")) .PRINT else if (std.mem.eql(u8, checkText, "INPUT")) .INPUT else if (std.mem.eql(u8, checkText, "LET")) .LET else if (std.mem.eql(u8, checkText, "IF")) .IF else if (std.mem.eql(u8, checkText, "THEN")) .THEN else if (std.mem.eql(u8, checkText, "ENDIF")) .ENDIF else if (std.mem.eql(u8, checkText, "WHILE")) .WHILE else if (std.mem.eql(u8, checkText, "REPEAT")) .REPEAT else if (std.mem.eql(u8, checkText, "ENDWHILE")) .ENDWHILE else if (std.mem.eql(u8, checkText, "GOTO")) .GOTO else if (std.mem.eql(u8, checkText, "LABEL")) .LABEL else .IDENT;
}
