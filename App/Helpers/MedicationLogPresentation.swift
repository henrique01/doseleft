import Foundation
import DoseCore

/// Shared presentation logic for dose history.
///
/// Two flows insert a "refund" entry at a scheduled dose's timestamp:
///
/// 1. Erase scheduled (synthetic) dose → inserts `.correction` with negative
///    `doseCount`. Both the synthetic row AND its compensating correction are
///    hidden — otherwise the user sees a phantom "Adjusted −N" pop up where
///    they just erased.
/// 2. "I missed today" → inserts `.missed` with negative `doseCount` at the
///    scheduled time. The synthetic row is hidden but the `.missed` log stays
///    visible (displayed as "Missed N tablet"), so the user has a record.
enum MedicationLogPresentation {

    private struct SuppressKey: Hashable {
        let t: Date
        let n: Int
    }

    /// Computed view of a medication's logs ready for display.
    /// - `synthetic`: the `.scheduled` entries to show in full-history views,
    ///   already filtered to exclude any that were erased via compensating correction.
    /// - `realLogs`: the medication's stored `DoseLog`s with the compensating
    ///   corrections removed (so they don't show up as standalone "Adjusted" rows).
    struct Presentation {
        let synthetic: [DoseLog]
        let realLogs: [DoseLog]
    }

    /// Resolve the displayable logs for `med` up to `now`. Pass `includeSynthetic:
    /// false` for the iPhone Recent Activity preview, which doesn't render
    /// synthetic scheduled rows (it only shows real `DoseLog`s).
    static func resolve(
        for med: Medication,
        now: Date = .now,
        calendar: Calendar = .current,
        includeSynthetic: Bool
    ) -> Presentation {
        // Two suppressor pools, both keyed on (timestamp, refund-amount):
        // - corrections: hide the synthetic AND hide the correction itself
        //   (used by the erase-scheduled flow, which should look like a clean delete).
        // - missed: hide the synthetic but keep the .missed log visible
        //   (so users see "Missed 1 tablet" in history instead of nothing).
        var corrections: [SuppressKey: [DoseLog]] = [:]
        var missed: [SuppressKey: [DoseLog]] = [:]
        for log in med.logsArray {
            switch log.source {
            case .correction where log.doseCount < 0:
                corrections[SuppressKey(t: log.timestamp, n: -log.doseCount), default: []].append(log)
            case .missed:
                missed[SuppressKey(t: log.timestamp, n: -log.doseCount), default: []].append(log)
            default:
                break
            }
        }

        var consumed: Set<UUID> = []
        var synthetic: [DoseLog] = []

        // Walk the schedule, consuming suppressors as we go. We always do this
        // walk (even when callers don't want synthetics) because we need to
        // know which corrections were consumed in order to hide them from the
        // real-logs list.
        DateBucketing.eachDay(from: med.startDate, through: now, calendar: calendar) { day in
            let weekday = calendar.component(.weekday, from: day)
            for s in med.schedulesArray where s.weekdays.contains(weekday) {
                guard let when = DateBucketing.setTime(
                    hour: s.timeHour, minute: s.timeMinute, on: day, calendar: calendar
                ) else { continue }
                guard when <= now && when >= med.startDate else { continue }
                let key = SuppressKey(t: when, n: s.doseCount)
                if var list = corrections[key], let match = list.popLast() {
                    corrections[key] = list
                    consumed.insert(match.id)
                    continue
                }
                if var list = missed[key], !list.isEmpty {
                    _ = list.popLast()
                    missed[key] = list
                    // .missed logs are NOT added to `consumed` — they stay visible.
                    continue
                }
                if includeSynthetic {
                    synthetic.append(DoseLog(timestamp: when, doseCount: s.doseCount, source: .scheduled))
                }
            }
        }

        let realLogs = med.logsArray.filter { !consumed.contains($0.id) }
        return Presentation(synthetic: synthetic, realLogs: realLogs)
    }
}
