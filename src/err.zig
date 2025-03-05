const std = @import("std");
const bson = @import("bson");

pub const Error = struct {
    pub const Code = enum(i32) {
        internal_error = 1,
        bad_value = 2,
        not_found = 59,
        unauthorized = 13,
        authentication_failed = 18,
        // todo: many, many, many more
        client_marked_killed = 46841,
    };
    // MongoError enumify the mongo error , so we can use code as error for returning
    pub const MongoError = error{
        ErrInternal,
        ErrBadValue,
        ErrClientMarkedKilled,
        ErrUnauthorized,
        ErrCommandNotFound,
        ErrUnknown,
        ErrAuthenticationFailed,
    };
    errmsg: []const u8,
    /// todo: enumify
    /// https://www.mongodb.com/docs/manual/reference/error-codes/
    code: i32,
    codeName: []const u8,

    pub fn code(self: @This()) Code {
        return @enumFromInt(self.code);
    }

    pub fn err(self: @This()) anyerror {
        switch (self.code) {
            @intFromEnum(Error.Code.internal_error) => return MongoError.ErrInternal,
            @intFromEnum(Error.Code.bad_value) => return MongoError.ErrBadValue,
            @intFromEnum(Error.Code.client_marked_killed) => return MongoError.ErrClientMarkedKilled,
            @intFromEnum(Error.Code.not_found) => return MongoError.ErrCommandNotFound,
            @intFromEnum(Error.Code.unauthorized) => return MongoError.ErrUnauthorized,
            @intFromEnum(Error.Code.authentication_failed) => return MongoError.ErrAuthenticationFailed,
            else => {
                std.debug.print("Unknown MongoDB error code: {d} ({s}): {s}\n", .{ self.code, self.codeName, self.errmsg });
                return MongoError.ErrUnknown;
            },
        }
    }
};

pub fn extractErr(allocator: std.mem.Allocator, doc: bson.types.RawBson) !bson.Owned(Error) {
    return doc.into(allocator, Error);
}

pub fn isErr(raw: bson.types.RawBson) bool {
    return switch (raw) {
        .document => |doc| if (doc.get("ok")) |ok| switch (ok) {
            .double => |doub| doub.value == 0.0,
            else => false,
        } else false,
        else => false,
    };
}
