const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const emitter = @import("emitter.zig");
const ast_lib = @import("ast.zig");

pub const Compiler = struct {
    lexer: lexer.Lexer,
    parser: parser.Parser,
    emitter: emitter.Emitter,

    pub fn init(source: []const u8, outputPath: []const u8) Compiler {
        var l = lexer.Lexer.init(source);
        const e = emitter.Emitter.init(outputPath);
        const p = parser.Parser.init(&l);

        return Compiler{
            .lexer = l,
            .parser = p,
            .emitter = e,
        };
    }

    pub fn compile(self: *Compiler) !void {
        const ast = try self.parser.parse();
        self.emit(ast);
        try self.emitter.writeFile();
    }

    fn emit(self: *Compiler, ast: ast_lib.AST) void {
        self.emitter.headerLine("#include <stdio.h>");
        self.emitter.headerLine("int main(void){");
        self.emitter.emit(ast);
        self.emitter.emitLine("return 0;");
        self.emitter.emitLine("}");
    }

    fn emitNode(self: *Compiler, node: ast_lib.AST.Node) void {
        switch (node) {
            .Statement => |stmt| switch (stmt) {
                .Print => |print| {
                    self.emitter.emit("printf(\"%.2f\\n\", (float)(");
                    self.emitNode(ast_lib.AST.Node{ .Expression = print.value });
                    self.emitter.emitLine("));");
                },
                .Input => |input| {
                    self.emitter.emitLine("if(0 == scanf(\"%f\", &" ++ input.variable.name ++ ")) {");
                    self.emitter.emitLine(input.variable.name ++ " = 0;");
                    self.emitter.emitLine("scanf(\"%*s\");");
                    self.emitter.emitLine("}");
                },
                .Let => |let| {
                    self.emitter.emit(let.variable.name ++ " = ");
                    self.emitNode(ast_lib.AST.Node{ .Expression = let.value });
                    self.emitter.emitLine(";");
                },
                .If => |if_stmt| {
                    self.emitter.emit("if(");
                    self.emitNode(ast_lib.AST.Node{ .Expression = if_stmt.condition });
                    self.emitter.emitLine("){");
                    for (if_stmt.body) |statement| {
                        self.emitNode(ast_lib.AST.Node{ .Statement = statement });
                    }
                    self.emitter.emitLine("}");
                },
                .While => |while_stmt| {
                    self.emitter.emit("while(");
                    self.emitNode(ast_lib.AST.Node{ .Expression = while_stmt.condition });
                    self.emitter.emitLine("){");
                    for (while_stmt.body) |statement| {
                        self.emitNode(ast_lib.AST.Node{ .Statement = statement });
                    }
                    self.emitter.emitLine("}");
                },
                .Label => |label| {
                    self.emitter.emitLine(label.name ++ ":");
                },
                .Goto => |goto| {
                    self.emitter.emitLine("goto " ++ goto.label ++ ";");
                },
            },
            .Expression => |expr| switch (expr) {
                .BinaryOp => |bin_op| {
                    self.emitNode(ast_lib.AST.Node{ .Expression = bin_op.left });
                    self.emitter.emit(bin_op.operator);
                    self.emitNode(ast_lib.AST.Node{ .Expression = bin_op.right });
                },
                .UnaryOp => |unary_op| {
                    self.emitter.emit(unary_op.operator);
                    self.emitNode(ast_lib.AST.Node{ .Expression = unary_op.operand });
                },
                .Literal => |literal| {
                    self.emitter.emit(literal.value);
                },
                .Identifier => |identifier| {
                    self.emitter.emit(identifier.name);
                },
            },
        }
    }
};
