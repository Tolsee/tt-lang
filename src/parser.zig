const std = @import("std");
const lexer = @import("lexer.zig");

pub const Parser = struct {
    lexer: lexer.Lexer,
    current_token: lexer.Token,

    pub fn init(l: lexer.Lexer) Parser {
        return Parser{
            .lexer = l,
            .current_token = l.getToken(),
        };
    }

    pub fn nextToken(self: *Parser) void {
        self.current_token = self.lexer.getToken();
    }

    pub fn parse(self: *Parser) !void {
        while (self.current_token.type != .EOF) {
            std.debug.print("Parsed Token: {s: <10} | Text: {s}\n", .{
                @tagName(self.current_token.type),
                self.current_token.text,
            });
            self.nextToken();
        }
    }

    fn parseProgram(self: *Parser) !void {
        while (self.current_token.type != .EOF) {
            try self.parseStatement();
        }
    }

    fn parseStatement(self: *Parser) !void {
        switch (self.current_token.type) {
            .PRINT => {
                self.nextToken();
                if (self.current_token.type == .STRING) {
                    self.nextToken();
                } else {
                    try self.parseExpression();
                }
                try self.expectNewline();
            },
            .IF => {
                self.nextToken();
                try self.parseComparison();
                try self.expectToken(.THEN);
                try self.expectNewline();
                while (self.current_token.type != .ENDIF) {
                    try self.parseStatement();
                }
                try self.expectToken(.ENDIF);
                try self.expectNewline();
            },
            .WHILE => {
                self.nextToken();
                try self.parseComparison();
                try self.expectToken(.REPEAT);
                try self.expectNewline();
                while (self.current_token.type != .ENDWHILE) {
                    try self.parseStatement();
                }
                try self.expectToken(.ENDWHILE);
                try self.expectNewline();
            },
            .LABEL => {
                self.nextToken();
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            .GOTO => {
                self.nextToken();
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            .LET => {
                self.nextToken();
                try self.expectToken(.IDENT);
                try self.expectToken(.EQ);
                try self.parseExpression();
                try self.expectNewline();
            },
            .INPUT => {
                self.nextToken();
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            else => return error.InvalidSyntax,
        }
    }

    fn parseComparison(self: *Parser) !void {
        try self.parseExpression();
        while (self.current_token.type == .EQEQ or self.current_token.type == .NOTEQ or self.current_token.type == .GT or self.current_token.type == .GTEQ or self.current_token.type == .LT or self.current_token.type == .LTEQ) {
            self.nextToken();
            try self.parseExpression();
        }
    }

    fn parseExpression(self: *Parser) !void {
        try self.parseTerm();
        while (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            self.nextToken();
            try self.parseTerm();
        }
    }

    fn parseTerm(self: *Parser) !void {
        try self.parseUnary();
        while (self.current_token.type == .ASTERISK or self.current_token.type == .SLASH) {
            self.nextToken();
            try self.parseUnary();
        }
    }

    fn parseUnary(self: *Parser) !void {
        if (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            self.nextToken();
        }
        try self.parsePrimary();
    }

    fn parsePrimary(self: *Parser) !void {
        switch (self.current_token.type) {
            .NUMBER, .IDENT => self.nextToken(),
            else => return error.InvalidSyntax,
        }
    }

    fn expectToken(self: *Parser, expected: lexer.TokenType) !void {
        if (self.current_token.type != expected) {
            return error.InvalidSyntax;
        }
        self.nextToken();
    }

    fn expectNewline(self: *Parser) !void {
        if (self.current_token.type != .NEWLINE) {
            return error.InvalidSyntax;
        }
        self.nextToken();
    }
};
