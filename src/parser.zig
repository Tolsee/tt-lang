const std = @import("std");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

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

    pub fn parse(self: *Parser) ![]ast.AST.Node {
        var ast_nodes = std.ArrayList(ast.AST.Node).init(std.heap.page_allocator);
        while (self.current_token.type != .EOF) {
            try ast_nodes.append(try self.parseStatement());
        }
        return ast_nodes.toOwnedSlice();
    }

    fn parseStatement(self: *Parser) !ast.AST.Node {
        switch (self.current_token.type) {
            .PRINT => {
                self.nextToken();
                if (self.current_token.type == .STRING) {
                    const value = ast.AST.constructLiteral(self.current_token.text);
                    self.nextToken();
                    return ast.AST.constructPrint(value);
                } else {
                    const value = try self.parseExpression();
                    return ast.AST.constructPrint(value);
                }
            },
            .IF => {
                self.nextToken();
                const condition = try self.parseComparison();
                try self.expectToken(.THEN);
                try self.expectNewline();
                var body = std.ArrayList(ast.AST.Statement).init(std.heap.page_allocator);
                while (self.current_token.type != .ENDIF) {
                    try body.append(try self.parseStatement().Statement);
                }
                try self.expectToken(.ENDIF);
                try self.expectNewline();
                return ast.AST.constructIf(condition, body.toOwnedSlice());
            },
            .WHILE => {
                self.nextToken();
                const condition = try self.parseComparison();
                try self.expectToken(.REPEAT);
                try self.expectNewline();
                var body = std.ArrayList(ast.AST.Statement).init(std.heap.page_allocator);
                while (self.current_token.type != .ENDWHILE) {
                    try body.append(try self.parseStatement().Statement);
                }
                try self.expectToken(.ENDWHILE);
                try self.expectNewline();
                return ast.AST.constructWhile(condition, body.toOwnedSlice());
            },
            .LABEL => {
                self.nextToken();
                const name = self.current_token.text;
                try self.expectToken(.IDENT);
                try self.expectNewline();
                return ast.AST.constructLabel(name);
            },
            .GOTO => {
                self.nextToken();
                const label = self.current_token.text;
                try self.expectToken(.IDENT);
                try self.expectNewline();
                return ast.AST.constructGoto(label);
            },
            .LET => {
                self.nextToken();
                const variable = ast.AST.constructIdentifier(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectToken(.EQ);
                const value = try self.parseExpression();
                try self.expectNewline();
                return ast.AST.constructLet(variable, value);
            },
            .INPUT => {
                self.nextToken();
                const variable = ast.AST.constructIdentifier(self.current_token.text);
                try self.expectToken(.IDENT);
                try self.expectNewline();
                return ast.AST.constructInput(variable);
            },
            else => return error.InvalidSyntax,
        }
    }

    fn parseComparison(self: *Parser) !ast.AST.Expression {
        var left = try self.parseExpression();
        while (self.isComparisonOperator()) {
            const operator = self.current_token.text;
            self.nextToken();
            const right = try self.parseExpression();
            left = ast.AST.constructBinaryOp(left, operator, right).Expression;
        }
        return left;
    }

    fn parseExpression(self: *Parser) !ast.AST.Expression {
        var left = try self.parseTerm();
        while (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            const operator = self.current_token.text;
            self.nextToken();
            const right = try self.parseTerm();
            left = ast.AST.constructBinaryOp(left, operator, right).Expression;
        }
        return left;
    }

    fn parseTerm(self: *Parser) !ast.AST.Expression {
        var left = try self.parseUnary();
        while (self.current_token.type == .ASTERISK or self.current_token.type == .SLASH) {
            const operator = self.current_token.text;
            self.nextToken();
            const right = try self.parseUnary();
            left = ast.AST.constructBinaryOp(left, operator, right).Expression;
        }
        return left;
    }

    fn parseUnary(self: *Parser) !ast.AST.Expression {
        if (self.current_token.type == .PLUS or self.current_token.type == .MINUS) {
            const operator = self.current_token.text;
            self.nextToken();
            const operand = try self.parsePrimary();
            return ast.AST.constructUnaryOp(operator, operand).Expression;
        }
        return try self.parsePrimary();
    }

    fn parsePrimary(self: *Parser) !ast.AST.Expression {
        switch (self.current_token.type) {
            .NUMBER => {
                const value = ast.AST.constructLiteral(self.current_token.text);
                self.nextToken();
                return value;
            },
            .IDENT => {
                const name = ast.AST.constructIdentifier(self.current_token.text);
                self.nextToken();
                return name;
            },
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

    fn isComparisonOperator(self: *Parser) bool {
        return self.current_token.type == .EQEQ or self.current_token.type == .NOTEQ or self.current_token.type == .GT or self.current_token.type == .GTEQ or self.current_token.type == .LT or self.current_token.type == .LTEQ;
    }
};
