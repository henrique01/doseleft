#if DEBUG
import Foundation
import SwiftData
import DoseCore

/// DEBUG-only sample data for Xcode `#Preview` blocks. Builds an in-memory
/// `ModelContainer` pre-populated with three realistic medications so screens
/// that depend on `@Query` or `@Bindable` instances have something to render.
enum PreviewFixtures {

    /// In-memory `ModelContainer` seeded with three meds + schedules + a few
    /// dose logs. Attach with `.modelContainer(PreviewFixtures.container())`.
    static func container() -> ModelContainer {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        let ctx = ModelContext(c)
        seed(into: ctx)
        try? ctx.save()
        return c
    }

    /// Empty in-memory container — for previewing empty states.
    static func emptyContainer() -> ModelContainer {
        ModelContainer.doseLeftShared(inMemory: true)
    }

    // MARK: - Sample meds (detached — for views that take a single Medication)

    /// Twice-daily inhaler started ~20 days ago. Mid-life of a 120-dose canister.
    static func scheduledMed() -> Medication {
        let med = Medication(
            name: "Flixotide",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.lavender.hex,
            totalDoses: 120,
            startDate: .now.addingTimeInterval(-20 * 86_400),
            trackingMode: .automatic
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, doseCount: 2, medication: med),
            DoseSchedule(timeHour: 20, doseCount: 2, medication: med),
        ]
        return med
    }

    /// Weekly click-pen with only one dose left — exercises the running-low banner.
    static func lowMed() -> Medication {
        let med = Medication(
            name: "Mounjaro",
            iconSymbol: MedicationIcon.clickPen.symbolName,
            colorHex: DLAccent.sage.hex,
            totalDoses: 4,
            startDate: .now.addingTimeInterval(-21 * 86_400),
            trackingMode: .automatic,
            clicksPerDose: 4,
            doseMg: 2.5
        )
        med.schedules = [
            DoseSchedule(timeHour: 9, doseCount: 1, weekdays: [2], medication: med),
        ]
        return med
    }

    /// Rescue inhaler — no schedule, manual logging.
    static func asNeededMed() -> Medication {
        Medication(
            name: "Ventolin",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.terracotta.hex,
            totalDoses: 200,
            startDate: .now.addingTimeInterval(-10 * 86_400),
            trackingMode: .manual,
            isAsNeeded: true
        )
    }

    /// Attaches a handful of `DoseLog` entries across today / yesterday / last
    /// week so `HistoryView` has all three sections populated.
    @discardableResult
    static func withLogs(_ med: Medication) -> Medication {
        let now = Date.now
        med.logs = [
            DoseLog(timestamp: now.addingTimeInterval(-2 * 3600), doseCount: 2, source: .manual, medication: med),
            DoseLog(timestamp: now.addingTimeInterval(-26 * 3600), doseCount: 2, source: .scheduled, medication: med),
            DoseLog(timestamp: now.addingTimeInterval(-3 * 86_400), doseCount: 2, source: .manual, medication: med),
            DoseLog(timestamp: now.addingTimeInterval(-5 * 86_400), doseCount: 2, source: .scheduled, medication: med),
        ]
        return med
    }

    // MARK: - Container seeding

    private static func seed(into ctx: ModelContext) {
        let scheduled = scheduledMed()
        ctx.insert(scheduled)
        scheduled.schedules?.forEach { ctx.insert($0) }
        withLogs(scheduled).logs?.forEach { ctx.insert($0) }

        let low = lowMed()
        ctx.insert(low)
        low.schedules?.forEach { ctx.insert($0) }

        let prn = asNeededMed()
        ctx.insert(prn)
    }
}
#endif
