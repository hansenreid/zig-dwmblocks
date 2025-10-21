const std = @import("std");
const zig_dwmblocks = @import("zig_dwmblocks");
const Battery = zig_dwmblocks.Battery;
const Time = zig_dwmblocks.Time;

const fs = std.fs;
const File = std.fs.File;

pub fn main() !u8 {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var args = std.process.args();

    // First arg is always the path
    _ = args.next();

    // Second arg is the command to run
    const arg = args.next() orelse {
        std.debug.print("No command provided\n", .{});
        return 1;
    };

    const cmd = std.meta.stringToEnum(command, arg) orelse {
        std.debug.print("Invalid Command: {s}\n", .{arg});
        return 1;
    };

    switch (cmd) {
        .battery => {
            const b: Battery = try .init();
            try stdout.print("{f}\n", .{b});
        },

        .time => {
            const t: Time = .now(
                .from_int(-5),
            );

            try stdout.print("{f}\n", .{t});
        },
    }

    try stdout.flush();

    return 0;
}

const command = enum {
    battery,
    time,
};
