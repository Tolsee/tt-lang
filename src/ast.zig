const std = @import("std");

pub const AST = struct {
    pub const Node = union(enum) {
        Statement: Statement,
        Expression: Expression,
    };

    pub const Statement = union(enum) {
        Print: Print,
        Input: Input,
        Let: Let,
        If: If,
        While: While,
        Label: Label,
        Goto: Goto,
    };

    pub const Expression = union(enum) {
        BinaryOp: BinaryOp,
        UnaryOp: UnaryOp,
        Literal: Literal,
        Identifier: Identifier,
    };

    pub const Print = struct {
        value: *const Expression,
    };

    pub const Input = struct {
        variable: *const Identifier,
    };

    pub const Let = struct {
        variable: *const Identifier,
        value: *const Expression,
    };

    pub const If = struct {
        condition: *const Expression,
        body: *const []Statement,
    };

    pub const While = struct {
        condition: *const Expression,
        body: *const []Statement,
    };

    pub const Label = struct {
        name: []const u8,
    };

    pub const Goto = struct {
        label: []const u8,
    };

    pub const BinaryOp = struct {
        left: *const Expression,
        operator: []const u8,
        right: *const Expression,
    };

    pub const UnaryOp = struct {
        operator: []const u8,
        operand: *const Expression,
    };

    pub const Literal = struct {
        value: []const u8,
    };

    pub const Identifier = struct {
        name: []const u8,
    };

    pub fn constructPrint(value: *const Expression) Node {
        return Node{ .Statement = Statement{ .Print = Print{ .value = value } } };
    }

    pub fn constructInput(variable: *const Identifier) Node {
        return Node{ .Statement = Statement{ .Input = Input{ .variable = variable } } };
    }

    pub fn constructLet(variable: *const Identifier, value: *const Expression) Node {
        return Node{ .Statement = Statement{ .Let = Let{ .variable = variable, .value = value } } };
    }

    pub fn constructIf(condition: *const Expression, body: *const []Statement) Node {
        return Node{ .Statement = Statement{ .If = If{ .condition = condition, .body = body } } };
    }

    pub fn constructWhile(condition: *const Expression, body: *const []Statement) Node {
        return Node{ .Statement = Statement{ .While = While{ .condition = condition, .body = body } } };
    }

    pub fn constructLabel(name: []const u8) Node {
        return Node{ .Statement = Statement{ .Label = Label{ .name = name } } };
    }

    pub fn constructGoto(label: []const u8) Node {
        return Node{ .Statement = Statement{ .Goto = Goto{ .label = label } } };
    }

    pub fn constructBinaryOp(left: *const Expression, operator: []const u8, right: *const Expression) Node {
        return Node{ .Expression = Expression{ .BinaryOp = BinaryOp{ .left = left, .operator = operator, .right = right } } };
    }

    pub fn constructUnaryOp(operator: []const u8, operand: *const Expression) Node {
        return Node{ .Expression = Expression{ .UnaryOp = UnaryOp{ .operator = operator, .operand = operand } } };
    }

    pub fn constructLiteral(value: []const u8) Node {
        return Node{ .Expression = Expression{ .Literal = Literal{ .value = value } } };
    }

    pub fn constructIdentifier(name: []const u8) Node {
        return Node{ .Expression = Expression{ .Identifier = Identifier{ .name = name } } };
    }

    pub fn traverse(self: *AST, node: Node, visit: fn (node: Node) void) void {
        visit(node);
        switch (node) {
            .Statement => |stmt| switch (stmt) {
                .Print => |print| self.traverse(Node{ .Expression = print.value.* }, visit),
                .Input => {},
                .Let => |let| self.traverse(Node{ .Expression = let.value.* }, visit),
                .If => |if_stmt| {
                    self.traverse(Node{ .Expression = if_stmt.condition.* }, visit);
                    for (if_stmt.body.*) |statement| {
                        self.traverse(Node{ .Statement = statement }, visit);
                    }
                },
                .While => |while_stmt| {
                    self.traverse(Node{ .Expression = while_stmt.condition.* }, visit);
                    for (while_stmt.body.*) |statement| {
                        self.traverse(Node{ .Statement = statement }, visit);
                    }
                },
                .Label => {},
                .Goto => {},
            },
            .Expression => |expr| switch (expr) {
                .BinaryOp => |bin_op| {
                    self.traverse(Node{ .Expression = bin_op.left.* }, visit);
                    self.traverse(Node{ .Expression = bin_op.right.* }, visit);
                },
                .UnaryOp => |unary_op| self.traverse(Node{ .Expression = unary_op.operand.* }, visit),
                .Literal => {},
                .Identifier => {},
            },
        }
    }

    pub fn debug(self: *AST, node: Node) void {
        self.traverse(node, printNode);
    }
};

pub fn printNode(node: AST.Node) void {
    switch (node) {
        .Statement => |stmt| switch (stmt) {
            .Print => |print| {
                std.debug.print("print ", .{});
                printNode(AST.Node{ .Expression = print.value.* });
                std.debug.print("\n", .{});
            },
            .Input => |input| {
                std.debug.print("input ", .{});
                printNode(AST.Node{ .Expression = AST.Expression{ .Identifier = input.variable.* } });
                std.debug.print("\n", .{});
            },
            .Let => |let| {
                std.debug.print("let ", .{});
                printNode(AST.Node{ .Expression = AST.Expression{ .Identifier = let.variable.* } });
                std.debug.print(" = ", .{});
                printNode(AST.Node{ .Expression = let.value.* });
                std.debug.print("\n", .{});
            },
            .If => |if_stmt| {
                std.debug.print("if ", .{});
                printNode(AST.Node{ .Expression = if_stmt.condition.* });
                std.debug.print(" then\n", .{});
                for (if_stmt.body.*) |statement| {
                    printNode(AST.Node{ .Statement = statement });
                }
                std.debug.print("end\n", .{});
            },
            .While => |while_stmt| {
                std.debug.print("while ", .{});
                printNode(AST.Node{ .Expression = while_stmt.condition.* });
                std.debug.print(" do\n", .{});
                for (while_stmt.body.*) |statement| {
                    printNode(AST.Node{ .Statement = statement });
                }
                std.debug.print("end\n", .{});
            },
            .Label => |label| {
                std.debug.print("label {s}\n", .{label.name});
            },
            .Goto => |goto| {
                std.debug.print("goto {s}\n", .{goto.label});
            },
        },
        .Expression => |expr| switch (expr) {
            .BinaryOp => |bin_op| {
                printNode(AST.Node{ .Expression = bin_op.left.* });
                std.debug.print(" {s} ", .{bin_op.operator});
                printNode(AST.Node{ .Expression = bin_op.right.* });
            },
            .UnaryOp => |unary_op| {
                std.debug.print("{s}", .{unary_op.operator});
                printNode(AST.Node{ .Expression = unary_op.operand.* });
            },
            .Literal => |literal| {
                std.debug.print("{s}", .{literal.value});
            },
            .Identifier => |identifier| {
                std.debug.print("{s}", .{identifier.name});
            },
        },
    }
}
