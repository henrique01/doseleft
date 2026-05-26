import Foundation
import SwiftData
import WidgetKit
import DoseCore

/// Shared mutating actions for dose logs used by both `MedicationDetailView`
/// and `HistoryView`.
enum DoseLogActions {

    /// Move a log to a new timestamp. Used to correct the recorded date of a
    /// reset or other manual entry after the fact. Dose math re-evaluates
    /// automatically because it reads `log.timestamp` at call time.
    static func updateTimestamp(_ log: DoseLog, to newDate: Date, for med: Medication, in context: ModelContext) {
        log.timestamp = newDate
        context.dlSave()
        Haptic.tap(.soft)
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Erase a dose log entry.
    ///
    /// - For real logs (`.manual`, `.correction`, `.reset`, `.missed`): deletes the record.
    /// - For synthetic `.scheduled` rows: inserts a compensating `.correction`
    ///   with negated `doseCount` at the same timestamp so `DoseMath` refunds
    ///   the dose. The presentation helper hides both the synthetic and the
    ///   compensating correction from history.
    static func erase(_ log: DoseLog, for med: Medication, in context: ModelContext) {
        applyErase(log, for: med, in: context)
        context.dlSave()
        Haptic.tap(.soft)
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Batched variant of `erase` for bulk delete in `HistoryView`'s Select
    /// mode. Applies the same per-log rule but saves the context, fires the
    /// haptic, reschedules notifications, and reloads widget timelines only
    /// once for the whole batch.
    static func eraseMany(_ logs: [DoseLog], for med: Medication, in context: ModelContext) {
        guard !logs.isEmpty else { return }
        for log in logs { applyErase(log, for: med, in: context) }
        context.dlSave()
        Haptic.tap(.soft)
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func applyErase(_ log: DoseLog, for med: Medication, in context: ModelContext) {
        if log.source == .scheduled {
            let comp = DoseLog(
                timestamp: log.timestamp,
                doseCount: -log.doseCount,
                source: .correction,
                medication: med
            )
            context.insert(comp)
        } else {
            context.delete(log)
        }
    }

    /// Mark today's most recent past-due scheduled dose as missed.
    ///
    /// Finds the latest scheduled time on `now`'s calendar day that is `<= now`
    /// and isn't already covered by a `.missed` log or a compensating
    /// `.correction`. Inserts a `.missed` log with `doseCount = -schedule.doseCount`
    /// at that scheduled timestamp, which:
    /// - Refunds the dose via `DoseMath.manualDosesUsed` (sums all logs).
    /// - Suppresses the matching synthetic `.scheduled` row in history.
    /// - Stays visible itself as a "Missed N tablet" entry.
    ///
    /// No-op if there's no eligible past-due scheduled dose today.
    /// Returns true if a missed log was inserted.
    @discardableResult
    static func logMissed(
        for med: Medication,
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard let target = MissedDosePlanning.eligibleMissedDose(for: med, now: now, calendar: calendar) else {
            return false
        }
        let entry = DoseLog(
            timestamp: target.when,
            doseCount: -target.doseCount,
            source: .missed,
            medication: med
        )
        context.insert(entry)
        context.dlSave()
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    /// `true` when there's at least one past-due scheduled dose today not yet
    /// marked missed or erased — i.e., the "I missed today" button has work to do.
    static func canLogMissed(
        for med: Medication,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        MissedDosePlanning.canLogMissed(for: med, now: now, calendar: calendar)
    }
}
