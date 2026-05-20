import Foundation

public enum DateBucketing {
    /// Iterate every day from `start` to `end` inclusive, calling `body` with the
    /// start-of-day in user's current calendar. Safe across DST: dates are derived
    /// via `Calendar.date(byAdding:.day:value:1)`, not by adding 86_400 seconds.
    public static func eachDay(from start: Date, through end: Date, calendar: Calendar = .current, body: (Date) -> Void) {
        guard start <= end else { return }
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            body(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return }
            day = next
        }
    }

    /// Returns the wall-clock time on `day` set to (hour, minute) without
    /// shifting by elapsed seconds — so 08:00 stays 08:00 across DST.
    public static func setTime(hour: Int, minute: Int, on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}
