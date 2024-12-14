const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const emitter = @import("emitter.zig");
const ast_lib = @import("ast.zig");

pub const Compiler = struct {
    lexer: lexer.Lexer,
    parser: parser.Parser,
    emitter: emitter.Emitter,
    allocator: std.mem.Allocator,
    source: []const u8,

    pub fn init(allocator: std.mem.Allocator, source: []const u8, outputPath: []const u8) Compiler {
        var compiler = Compiler{
            .lexer = lexer.Lexer.init(source),
            .parser = undefined,
            .emitter = emitter.Emitter.init(outputPath),
            .allocator = allocator,
            .source = source,
        };

        compiler.parser = parser.Parser.init(&compiler.lexer);
        return compiler;
    }

    pub fn compile(self: *Compiler) !void {
        const ast = try self.parser.parse();
        var a = ast_lib.AST{};
        for (ast) |node| {
            a.debug(node);
        }
        try self.emit(ast);
        try self.emitter.writeFile();
    }

    fn emit(self: *Compiler, ast: []ast_lib.AST.Node) !void {
        try self.emitter.headerLine("#include <stdio.h>");
        try self.emitter.headerLine("int main(void){");

        // Emit variable declarations
        try self.emitter.headerLine("float a, b, c, nums;"); // Add other variables as needed

        for (ast) |node| {
            try self.emitNode(node);
        }
        try self.emitter.emitLine("return 0;");
        try self.emitter.emitLine("}");
    }

    fn emitNode(self: *Compiler, node: ast_lib.AST.Node) !void {
        switch (node) {
            .Statement => |stmt| switch (stmt) {
                .Print => |print| {
                    try self.emitter.emit("printf(\"%.2f\\n\", (float)(");
                    try self.emitNode(.{ .Expression = print.value.* });
                    try self.emitter.emitLine("));");
                },
                .Input => |input| {
                    try self.emitter.emit(try std.fmt.allocPrint(self.allocator, "if(0 == scanf(\"%f\", &{s})) {{", .{input.variable.name}));
                    try self.emitter.emitLine("");

                    try self.emitter.emit(try std.fmt.allocPrint(self.allocator, "    {s} = 0;", .{input.variable.name}));
                    try self.emitter.emitLine("");

                    try self.emitter.emitLine("    scanf(\"%*s\");");
                    try self.emitter.emitLine("}");
                },
                .Let => |let| {
                    try self.emitter.emit(try std.fmt.allocPrint(self.allocator, "{s} = ", .{let.variable.name}));
                    try self.emitNode(.{ .Expression = let.value.* });
                    try self.emitter.emitLine(";");
                },
                .If => |if_stmt| {
                    try self.emitter.emit("if(");
                    try self.emitNode(.{ .Expression = if_stmt.condition.* });
                    try self.emitter.emitLine("){");

                    for (if_stmt.body.*) |statement| {
                        try self.emitNode(.{ .Statement = statement });
                    }
                    try self.emitter.emitLine("}");
                },
                .While => |while_stmt| {
                    try self.emitter.emit("while(");
                    try self.emitNode(.{ .Expression = while_stmt.condition.* });
                    try self.emitter.emitLine("){");

                    for (while_stmt.body.*) |statement| {
                        try self.emitNode(.{ .Statement = statement });
                    }
                    try self.emitter.emitLine("}");
                },
                .Label => |label| {
                    try self.emitter.emit(try std.fmt.allocPrint(self.allocator, "{s}:", .{label.name}));
                    try self.emitter.emitLine("");
                },
                .Goto => |goto| {
                    try self.emitter.emit(try std.fmt.allocPrint(self.allocator, "goto {s};", .{goto.label}));
                    try self.emitter.emitLine("");
                },
            },
            .Expression => |expr| switch (expr) {
                .BinaryOp => |bin_op| {
                    try self.emitNode(.{ .Expression = bin_op.left.* });
                    try self.emitter.emit(bin_op.operator);
                    try self.emitNode(.{ .Expression = bin_op.right.* });
                },
                .UnaryOp => |unary_op| {
                    try self.emitter.emit(unary_op.operator);
                    try self.emitNode(.{ .Expression = unary_op.operand.* });
                },
                .Literal => |literal| {
                    try self.emitter.emit(literal.value);
                },
                .Identifier => |identifier| {
                    try self.emitter.emit(identifier.name);
                },
            },
        }
    }
};
