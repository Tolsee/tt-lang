const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const emitter = @import("emitter.zig");

pub const Compiler = struct {
    lexer: lexer.Lexer,
    parser: parser.Parser,
    emitter: emitter.Emitter,

    pub fn init(source: []const u8, outputPath: []const u8) Compiler {
        var l = lexer.Lexer.init(source);
        var e = emitter.Emitter.init(outputPath);
        var p = parser.Parser.init(&l);
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

    fn emit(self: *Compiler, ast: []const u8) void {
        self.emitter.headerLine("#include <stdio.h>");
        self.emitter.headerLine("int main(void){");
        self.emitter.emit(ast);
        self.emitter.emitLine("return 0;");
        self.emitter.emitLine("}");
    }
};
