import Foundation

/// Pure helpers for the "I missed today" flow.
///
/// `.missed` logs carry a negative `doseCount` at the timestamp of the scheduled
/// dose they replace. That timestamp + amount lets `MedicationLogPresentation`
/// suppress the matching synthetic `.scheduled` row, and `DoseMath.manualDosesUsed`
/// refunds the dose automatically.
public enum MissedDosePlanning {

    /// The most recent past-due scheduled dose on today's calendar day that
    /// isn't already covered by a suppressor log (`.missed` or negative
    /// `.correction` at the same timestamp). `nil` when there's no work to do.
    public static func eligibleMissedDose(
        for med: Medication,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (when: Date, doseCount: Int)? {
        let dayStart = calendar.startOfDay(for: now)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        let weekday = calendar.component(.weekday, from: now)

        struct Key: Hashable { let t: Date; let n: Int }
        var suppressed: [Key: Int] = [:]
        var lastResetAt: Date?
        for log in med.logsArray {
            if log.source == .reset {
                if lastResetAt.map({ log.timestamp > $0 }) ?? true {
                    lastResetAt = log.timestamp
                }
            }
            guard log.timestamp >= dayStart && log.timestamp < dayEnd else { continue }
            switch log.source {
            case .missed:
                suppressed[Key(t: log.timestamp, n: -log.doseCount), default: 0] += 1
            case .correction where log.doseCount < 0:
                suppressed[Key(t: log.timestamp, n: -log.doseCount), default: 0] += 1
            default:
                break
            }
        }

        var candidates: [(Date, Int)] = []
        for s in med.schedulesArray where s.weekdays.contains(weekday) {
            guard let when = DateBucketing.setTime(
                hour: s.timeHour, minute: s.timeMinute, on: now, calendar: calendar
            ) else { continue }
            guard when <= now && when >= med.startDate else { continue }
            candidates.append((when, s.doseCount))
        }
        candidates.sort { $0.0 > $1.0 }

        for (when, doseCount) in candidates {
            // A reset re-baselines the container, refunding everything used up
            // to that point. Any scheduled dose at or before the most recent
            // reset is already accounted for — you can't "miss" it again.
            if let lastResetAt, lastResetAt >= when {
                continue
            }
            let key = Key(t: when, n: doseCount)
            let used = suppressed[key, default: 0]
            if used > 0 {
                suppressed[key] = used - 1
                continue
            }
            return (when, doseCount)
        }
        return nil
    }

    /// `true` when "I missed today" has work to do for `med`.
    public static func canLogMissed(
        for med: Medication,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        eligibleMissedDose(for: med, now: now, calendar: calendar) != nil
    }
}
