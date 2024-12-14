const std = @import("std");

pub const Emitter = struct {
    fullPath: []const u8,
    header: []u8,
    code: []u8,

    pub fn init(fullPath: []const u8) Emitter {
        return Emitter{
            .fullPath = fullPath,
            .header = "",
            .code = "",
        };
    }

    pub fn emit(self: *Emitter, code: []const u8) void {
        self.code = std.mem.concat(self.code, code);
    }

    pub fn emitLine(self: *Emitter, code: []const u8) void {
        self.code = std.mem.concat(self.code, code);
        self.code = std.mem.concat(self.code, "\n");
    }

    pub fn headerLine(self: *Emitter, code: []const u8) void {
        self.header = std.mem.concat(self.header, code);
        self.header = std.mem.concat(self.header, "\n");
    }

    pub fn writeFile(self: *Emitter) !void {
        var outputFile = try std.fs.cwd().createFile(self.fullPath, .{});
        defer outputFile.close();
        try outputFile.write(self.header);
        try outputFile.write(self.code);
    }
};
