const std = @import("std");
const lexer = @import("lexer.zig");

pub const Parser = struct {
    lexer: *lexer.Lexer,
    current_token: lexer.Token,

    pub fn init(l: *lexer.Lexer) Parser {
        return Parser{
            .lexer = l,
            .current_token = l.getToken(),
        };
    }

    pub fn nextToken(self: *Parser) void {
        self.current_token = self.lexer.getToken();
    }

    pub fn parse(self: *Parser) ![]const u8 {
        var ast = std.ArrayList([]const u8).init(std.heap.page_allocator);
        while (self.current_token.type != .EOF) {
            try ast.append(try self.parseStatement());
        }
        return ast.toOwnedSlice();
    }

    fn parseStatement(self: *Parser) ![]const u8 {
        var statement = std.ArrayList([]const u8).init(std.heap.page_allocator);
        switch (self.current_token.type) {
            .PRINT => {
                self.nextToken();
                if (self.current_token.type == .STRING) {
                    try statement.append(self.current_token.text);
                    self.nextToken();
                } else {
                    try statement.append(try self.parseExpression());
                }
                try self.expectNewline();
            },
            .IF => {
                self.nextToken();
                try statement.append(try self.parseComparison());
                try self.expectToken(.THEN);
                try self.expectNewline();
                while (self.current_token.type != .ENDIF) {
                    try statement.append(try self.parseStatement());
                }
                try self.expectToken(.ENDIF);
                try self.expectNewline();
            },
            .WHILE => {
                self.nextToken();
                try statement.append(try self.parseComparison());
                try self.expectToken(.REPEAT);
                try self.expectNewline();
                while (self.current_token.type != .ENDWHILE) {
                    try statement.append(try self.parseStatement());
                }
                try self.expectToken(.ENDWHILE);
                try self.expectNewline();
            },
            .LABEL => {
                self.nextToken();
                try statement.append(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            .GOTO => {
                self.nextToken();
                try statement.append(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            .LET => {
                self.nextToken();
                try statement.append(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectToken(.EQ);
                try statement.append(try self.parseExpression());
                try self.expectNewline();
            },
            .INPUT => {
                self.nextToken();
                try statement.append(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectNewline();
            },
            else => return error.InvalidSyntax,
        }
        return statement.toOwnedSlice();
    }

    fn parseComparison(self: *Parser) ![]const u8 {
        var comparison = std.ArrayList([]const u8).init(std.heap.page_allocator);
        try comparison.append(try self.parseExpression());
        while (self.isComparisonOperator()) {
            try comparison.append(self.current_token.text);
            self.nextToken();
            try comparison.append(try self.parseExpression());
        }
        return comparison.toOwnedSlice();
    }

    fn parseExpression(self: *Parser) ![]const u8 {
        var expression = std.ArrayList([]const u8).init(std.heap.page_allocator);
        try expression.append(try self.parseTerm());
        while (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            try expression.append(self.current_token.text);
            self.nextToken();
            try expression.append(try self.parseTerm());
        }
        return expression.toOwnedSlice();
    }

    fn parseTerm(self: *Parser) ![]const u8 {
        var term = std.ArrayList([]const u8).init(std.heap.page_allocator);
        try term.append(try self.parseUnary());
        while (self.current_token.type == .ASTERISK or self.current_token.type == .SLASH) {
            try term.append(self.current_token.text);
            self.nextToken();
            try term.append(try self.parseUnary());
        }
        return term.toOwnedSlice();
    }

    fn parseUnary(self: *Parser) ![]const u8 {
        var unary = std.ArrayList([]const u8).init(std.heap.page_allocator);
        if (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            try unary.append(self.current_token.text);
            self.nextToken();
        }
        try unary.append(try self.parsePrimary());
        return unary.toOwnedSlice();
    }

    fn parsePrimary(self: *Parser) ![]const u8 {
        var primary = std.ArrayList([]const u8).init(std.heap.page_allocator);
        switch (self.current_token.type) {
            .NUMBER, .IDENT => {
                try primary.append(self.current_token.text);
                self.nextToken();
            },
            else => return error.InvalidSyntax,
        }
        return primary.toOwnedSlice();
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

    fn isComparisonOperator(self: *Parser) bool {
        return self.current_token.type == .EQEQ or self.current_token.type == .NOTEQ or self.current_token.type == .GT or self.current_token.type == .GTEQ or self.current_token.type == .LT or self.current_token.type == .LTEQ;
    }
};
