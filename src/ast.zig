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
        value: Expression,
    };

    pub const Input = struct {
        variable: Identifier,
    };

    pub const Let = struct {
        variable: Identifier,
        value: Expression,
    };

    pub const If = struct {
        condition: Expression,
        body: []Statement,
    };

    pub const While = struct {
        condition: Expression,
        body: []Statement,
    };

    pub const Label = struct {
        name: []const u8,
    };

    pub const Goto = struct {
        label: []const u8,
    };

    pub const BinaryOp = struct {
        left: Expression,
        operator: []const u8,
        right: Expression,
    };

    pub const UnaryOp = struct {
        operator: []const u8,
        operand: Expression,
    };

    pub const Literal = struct {
        value: []const u8,
    };

    pub const Identifier = struct {
        name: []const u8,
    };

    pub fn constructPrint(value: Expression) Node {
        return Node{ .Statement = Statement{ .Print = Print{ .value = value } } };
    }

    pub fn constructInput(variable: Identifier) Node {
        return Node{ .Statement = Statement{ .Input = Input{ .variable = variable } } };
    }

    pub fn constructLet(variable: Identifier, value: Expression) Node {
        return Node{ .Statement = Statement{ .Let = Let{ .variable = variable, .value = value } } };
    }

    pub fn constructIf(condition: Expression, body: []Statement) Node {
        return Node{ .Statement = Statement{ .If = If{ .condition = condition, .body = body } } };
    }

    pub fn constructWhile(condition: Expression, body: []Statement) Node {
        return Node{ .Statement = Statement{ .While = While{ .condition = condition, .body = body } } };
    }

    pub fn constructLabel(name: []const u8) Node {
        return Node{ .Statement = Statement{ .Label = Label{ .name = name } } };
    }

    pub fn constructGoto(label: []const u8) Node {
        return Node{ .Statement = Statement{ .Goto = Goto{ .label = label } } };
    }

    pub fn constructBinaryOp(left: Expression, operator: []const u8, right: Expression) Node {
        return Node{ .Expression = Expression{ .BinaryOp = BinaryOp{ .left = left, .operator = operator, .right = right } } };
    }

    pub fn constructUnaryOp(operator: []const u8, operand: Expression) Node {
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
                .Print => |print| self.traverse(print.value, visit),
                .Input => {},
                .Let => |let| self.traverse(let.value, visit),
                .If => |if_stmt| {
                    self.traverse(if_stmt.condition, visit);
                    for (if_stmt.body) |statement| {
                        self.traverse(Node{ .Statement = statement }, visit);
                    }
                },
                .While => |while_stmt| {
                    self.traverse(while_stmt.condition, visit);
                    for (while_stmt.body) |statement| {
                        self.traverse(Node{ .Statement = statement }, visit);
                    }
                },
                .Label => {},
                .Goto => {},
            },
            .Expression => |expr| switch (expr) {
                .BinaryOp => |bin_op| {
                    self.traverse(Node{ .Expression = bin_op.left }, visit);
                    self.traverse(Node{ .Expression = bin_op.right }, visit);
                },
                .UnaryOp => |unary_op| self.traverse(Node{ .Expression = unary_op.operand }, visit),
                .Literal => {},
                .Identifier => {},
            },
        }
    }
};
