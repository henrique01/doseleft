#if DEBUG
import Foundation
import SwiftData
import DoseCore

/// DEBUG-only sample data for watchOS `#Preview` blocks. Select an Apple Watch
/// canvas device in Xcode (e.g. Apple Watch Series 9) to render.
enum PreviewFixtures {

    static func container() -> ModelContainer {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        let ctx = ModelContext(c)
        let scheduled = scheduledMed()
        ctx.insert(scheduled)
        scheduled.schedules?.forEach { ctx.insert($0) }
        let prn = asNeededMed()
        ctx.insert(prn)
        try? ctx.save()
        return c
    }

    static func emptyContainer() -> ModelContainer {
        ModelContainer.doseLeftShared(inMemory: true)
    }

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
}
#endif
