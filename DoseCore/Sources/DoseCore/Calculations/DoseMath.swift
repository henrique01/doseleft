import Foundation

/// Pure functions. No I/O, no `Date.now` calls — the caller always provides `now`.
/// This is the entire correctness model: counts are computed on demand from
///   totalDoses − scheduledDosesUsed(now) − manualDosesUsed(now)
/// so they are right whether the user opened the app today, last month, or never.
public enum DoseMath {

    /// Sum of `schedule.doseCount` for every (day, schedule) pair where the
    /// scheduled wall-clock time falls within `[start, end]`.
    public static func scheduledDosesUsed(
        med: Medication,
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> Int {
        // Freeze-the-clock semantics: while paused, no further scheduled doses
        // are consumed past `pausedAt`. The resume helper shifts `startDate`
        // forward by the paused duration so the post-resume window is the same
        // length as the unpaused portion.
        let effectiveEnd = med.pausedAt.map { min(end, $0) } ?? end
        guard start <= effectiveEnd else { return 0 }
        var total = 0
        let schedules = med.schedulesArray
        DateBucketing.eachDay(from: start, through: effectiveEnd, calendar: calendar) { day in
            let weekday = calendar.component(.weekday, from: day)
            for schedule in schedules where schedule.weekdays.contains(weekday) {
                guard let when = DateBucketing.setTime(
                    hour: schedule.timeHour,
                    minute: schedule.timeMinute,
                    on: day,
                    calendar: calendar
                ) else { continue }
                if when >= start && when <= effectiveEnd {
                    total += schedule.doseCount
                }
            }
        }
        return total
    }

    /// Sum of all `DoseLog.doseCount` up to and including `date`. May be negative
    /// for `.correction` / `.reset` entries — that is intentional, so a reset
    /// can refund the unused portion of the previous container (PRD edge case #8).
    public static func manualDosesUsed(med: Medication, by date: Date) -> Int {
        med.logsArray.reduce(0) { acc, log in
            log.timestamp <= date ? acc + log.doseCount : acc
        }
    }

    /// `max(0, totalDoses − scheduledDosesUsed − manualDosesUsed)`.
    /// Clamped at zero so a long absence shows an empty container, not negatives.
    public static func dosesRemaining(med: Medication, at date: Date, calendar: Calendar = .current) -> Int {
        let scheduled = scheduledDosesUsed(med: med, from: med.startDate, to: date, calendar: calendar)
        let manual = manualDosesUsed(med: med, by: date)
        return max(0, med.totalDoses - scheduled - manual)
    }

    /// Average doses consumed per day according to the active schedules.
    /// `Σ (schedule.doseCount × schedule.weekdays.count) / 7`.
    public static func dailyDoseRate(med: Medication) -> Double {
        let weekly = med.schedulesArray.reduce(0) { $0 + $1.doseCount * $1.weekdays.count }
        return Double(weekly) / 7.0
    }

    /// Estimated end date based on current remaining and average daily rate.
    /// `nil` if the schedule is empty (no consumption rate).
    public static func projectedEndDate(med: Medication, at date: Date, calendar: Calendar = .current) -> Date? {
        let rate = dailyDoseRate(med: med)
        guard rate > 0 else { return nil }
        let remaining = dosesRemaining(med: med, at: date, calendar: calendar)
        let days = Double(remaining) / rate
        return calendar.date(byAdding: .second, value: Int(days * 86_400), to: date)
    }

    /// Whole days until empty at the current rate. Floored — a partial last day
    /// is not promised. `0` means today is the last day.
    public static func daysRemaining(med: Medication, at date: Date, calendar: Calendar = .current) -> Int {
        let rate = dailyDoseRate(med: med)
        guard rate > 0 else { return 0 }
        let remaining = dosesRemaining(med: med, at: date, calendar: calendar)
        return Int((Double(remaining) / rate).rounded(.down))
    }

    /// `true` once supply is low. For rescue meds, compares `dosesRemaining` to
    /// `reminderLeadDoses` (no consumption rate). Otherwise, `daysRemaining ≤ reminderLeadDays`.
    public static func isRunningLow(med: Medication, at date: Date, calendar: Calendar = .current) -> Bool {
        if med.isAsNeeded {
            return dosesRemaining(med: med, at: date, calendar: calendar) <= med.reminderLeadDoses
        }
        return daysRemaining(med: med, at: date, calendar: calendar) <= med.reminderLeadDays
    }

    /// Next upcoming scheduled dose time strictly after `date`. Returns `nil`
    /// while the medication is paused.
    public static func nextDose(med: Medication, after date: Date, calendar: Calendar = .current) -> (date: Date, schedule: DoseSchedule)? {
        if med.pausedAt != nil { return nil }
        var best: (Date, DoseSchedule)?
        // Look up to 8 days ahead — covers any weekday pattern.
        let horizon = calendar.date(byAdding: .day, value: 8, to: date) ?? date
        let schedules = med.schedulesArray
        DateBucketing.eachDay(from: date, through: horizon, calendar: calendar) { day in
            let weekday = calendar.component(.weekday, from: day)
            for schedule in schedules where schedule.weekdays.contains(weekday) {
                guard let when = DateBucketing.setTime(
                    hour: schedule.timeHour, minute: schedule.timeMinute, on: day, calendar: calendar
                ) else { continue }
                if when > date {
                    if best == nil || when < best!.0 {
                        best = (when, schedule)
                    }
                }
            }
        }
        return best.map { (date: $0.0, schedule: $0.1) }
    }
}
