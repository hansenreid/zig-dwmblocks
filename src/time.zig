const std = @import("std");
const Io = std.Io;
const Clock = Io.Clock;
const time = std.time;
const Writer = std.Io.Writer;

pub const Time = struct {
    year: Year,
    month: Month,
    day: Day,
    hour: Hour,
    minute: Minute,
    second: Second,

    pub fn format(
        self: Time,
        writer: *Writer,
    ) !void {
        try writer.print("{f}-{f}-{f} {f}:{f}:{f}", .{
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
        });
    }

    pub fn now(io: Io, offset: Hour) !Time {
        var seconds: Second = try .now(io);
        seconds = seconds.with_offset(offset);

        var days, seconds = seconds.to_days();
        const years, days = days.to_years();
        const months, days = days.to_months(years);
        const hours, seconds = seconds.to_hours();
        const minutes, seconds = seconds.to_minutes();

        return .{
            .year = years,
            .month = months,
            .day = days,
            .hour = hours,
            .minute = minutes,
            .second = seconds,
        };
    }

    pub const Year = enum(u16) {
        _,

        const start_year: u16 = 1970;

        pub fn format(
            self: Year,
            writer: *Writer,
        ) !void {
            try writer.print("{d}", .{self});
        }

        pub fn from_days(d: Day) struct { Year, Day } {
            var days = @intFromEnum(d);
            var year: u16 = 1970;
            while (days >= time.epoch.getDaysInYear(year)) {
                days = days - time.epoch.getDaysInYear(year);
                year = year + 1;
            }

            return .{
                @enumFromInt(year),
                @enumFromInt(days),
            };
        }
    };

    pub const Month = enum(u4) {
        _,

        pub fn format(
            self: Month,
            writer: *Writer,
        ) !void {
            try writer.print("{d:0>2}", .{self});
        }

        pub fn from_days(y: Year, d: Day) struct { Month, Day } {
            var days = @intFromEnum(d);
            const year = @intFromEnum(y);
            var month: time.epoch.Month = .jan;

            while (days >= time.epoch.getDaysInMonth(year, month)) {
                days = days - time.epoch.getDaysInMonth(year, month);

                month = @enumFromInt(month.numeric() + 1);
            }

            days = days + 1;

            return .{
                @enumFromInt(@intFromEnum(month)),
                @enumFromInt(days),
            };
        }
    };

    pub const Day = enum(u64) {
        _,

        pub fn format(
            self: Day,
            writer: *Writer,
        ) !void {
            const d: u63 = @intCast(@intFromEnum(self));
            try writer.print("{d:0>2}", .{d});
        }

        pub fn to_years(d: Day) struct { Year, Day } {
            var days = @intFromEnum(d);
            var year: u16 = Year.start_year;
            while (days >= time.epoch.getDaysInYear(year)) {
                days = days - time.epoch.getDaysInYear(year);
                year = year + 1;
            }

            return .{
                @enumFromInt(year),
                @enumFromInt(days),
            };
        }

        pub fn to_months(d: Day, y: Year) struct { Month, Day } {
            var days = @intFromEnum(d);
            const year = @intFromEnum(y);
            var month: time.epoch.Month = .jan;

            while (days >= time.epoch.getDaysInMonth(year, month)) {
                days = days - time.epoch.getDaysInMonth(year, month);

                month = @enumFromInt(month.numeric() + 1);
            }

            days = days + 1;

            return .{
                @enumFromInt(@intFromEnum(month)),
                @enumFromInt(days),
            };
        }
    };

    pub const Hour = enum(i6) {
        _,

        pub fn format(
            self: Hour,
            writer: *Writer,
        ) !void {
            const h: u63 = @intCast(@intFromEnum(self));
            try writer.print("{d:0>2}", .{h});
        }

        pub fn from_int(int: i6) Hour {
            return @enumFromInt(int);
        }
    };

    pub const Minute = enum(u64) {
        _,

        pub fn format(
            self: Minute,
            writer: *Writer,
        ) !void {
            const m: u63 = @intCast(@intFromEnum(self));
            try writer.print("{d:0>2}", .{m});
        }
    };

    pub const Second = enum(i64) {
        _,

        pub fn now(io: Io) !Second {
            const n = try Clock.now(.real, io);
            return @enumFromInt(n.toSeconds());
        }

        fn with_offset(sec: Second, offset: Hour) Second {
            const offset_int: i64 = @intFromEnum(offset);
            const offset_seconds: i64 = offset_int * time.s_per_hour;
            const s = @intFromEnum(sec) + offset_seconds;
            return @enumFromInt(s);
        }

        pub fn format(
            self: Second,
            writer: *Writer,
        ) !void {
            const s: u63 = @intCast(@intFromEnum(self));
            try writer.print("{d:0>2}", .{s});
        }

        pub fn to_minutes(s: Second) struct { Minute, Second } {
            const minute = @divFloor(@intFromEnum(s), time.s_per_min);
            const remaining = @mod(@intFromEnum(s), time.s_per_min);

            return .{
                @enumFromInt(minute),
                @enumFromInt(remaining),
            };
        }

        pub fn to_hours(s: Second) struct { Hour, Second } {
            var hour = @divFloor(@intFromEnum(s), time.s_per_hour);
            const remaining = @mod(@intFromEnum(s), time.s_per_hour);

            const use_24_hour_time = false;
            if (hour > 12 and !use_24_hour_time) {
                hour = hour - 12;
            }

            return .{
                @enumFromInt(hour),
                @enumFromInt(remaining),
            };
        }

        pub fn to_days(s: Second) struct { Day, Second } {
            const day = @divFloor(@intFromEnum(s), time.s_per_day);
            const remaining = @mod(@intFromEnum(s), time.s_per_day);

            return .{
                @enumFromInt(day),
                @enumFromInt(remaining),
            };
        }
    };
};
