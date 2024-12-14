const std = @import("std");

pub const Emitter = struct {
    fullPath: []const u8,
    header: std.ArrayList(u8),
    code: std.ArrayList(u8),

    pub fn init(fullPath: []const u8) Emitter {
        return Emitter{
            .fullPath = fullPath,
            .header = std.ArrayList(u8).init(std.heap.page_allocator),
            .code = std.ArrayList(u8).init(std.heap.page_allocator),
        };
    }

    pub fn emit(self: *Emitter, code: []const u8) void {
        _ = self.code.appendSlice(code);
    }

    pub fn emitLine(self: *Emitter, code: []const u8) void {
        _ = self.code.appendSlice(code);
        _ = self.code.appendSlice("\n");
    }

    pub fn headerLine(self: *Emitter, code: []const u8) void {
        _ = self.header.appendSlice(code);
        _ = self.header.appendSlice("\n");
    }

    pub fn writeFile(self: *Emitter) !void {
        var outputFile = try std.fs.cwd().createFile(self.fullPath, .{});
        defer outputFile.close();
        try outputFile.write(self.header.toOwnedSlice());
        try outputFile.write(self.code.toOwnedSlice());
    }
};
