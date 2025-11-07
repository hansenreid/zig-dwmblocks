const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const File = std.fs.File;
const Writer = std.Io.Writer;

pub const Battery = struct {
    capacity: u8,
    status: battery_status,

    pub const battery_status = enum {
        Charging,
        Discharging,
        NotCharging,
        Full,
    };

    pub fn init(io: Io) !Battery {
        const cap = try get_battery_capacity(io);
        const status = try get_battery_status(io);
        return .{
            .capacity = cap,
            .status = status,
        };
    }

    pub fn format(
        self: Battery,
        writer: *Writer,
    ) !void {
        const charging = switch (self.status) {
            .Charging, .Full => "󰚥",
            .Discharging => "",
            .NotCharging => "󰚦",
        };

        const cap_icon = switch (self.capacity) {
            0...25 => "󱊡",
            26...75 => "󱊢",
            else => "󱊣",
        };

        try writer.print("{s} {s} {d}", .{
            charging,
            cap_icon,
            self.capacity,
        });
    }

    pub fn get_battery_capacity(io: Io) !u8 {
        const f = try fs.openFileAbsolute("/sys/class/power_supply/BAT0/capacity", .{ .mode = .read_only });
        defer f.close();

        var buf: [4]u8 = undefined;
        var r = f.reader(io, &buf);
        var i = &r.interface;

        const s = try i.takeDelimiterExclusive('\n');
        return std.fmt.parseInt(u8, s, 10);
    }

    pub fn get_battery_status(io: Io) !battery_status {
        const f = try fs.openFileAbsolute("/sys/class/power_supply/BAT0/status", .{ .mode = .read_only });
        defer f.close();

        var buf: [32]u8 = undefined;
        var r = f.reader(io, &buf);
        var i = &r.interface;

        const s = try i.takeDelimiterExclusive('\n');
        if (std.mem.eql(u8, s, "Not charging")) {
            return .NotCharging;
        }

        return std.meta.stringToEnum(battery_status, s) orelse {
            std.debug.print("Invalid Status: |{s}|\n", .{s});
            return error.InvalidStatus;
        };
    }
};
