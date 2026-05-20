import AppIntents
import SwiftData
import WidgetKit
import DoseCore

/// Interactive log-dose button on the medium widget. Inserts a `.manual` log
/// and reloads the timeline so the ring updates immediately.
struct WidgetLogDoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log dose"
    static var description = IntentDescription("Log a dose from the widget.")

    @Parameter(title: "Medication ID") var medicationID: String

    init() { self.medicationID = "" }
    init(medicationID: String) { self.medicationID = medicationID }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: medicationID) else { return .result() }
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        guard let med = try ctx.fetch(
            FetchDescriptor<Medication>(predicate: #Predicate { $0.id == uuid })
        ).first else { return .result() }
        let count = med.schedulesArray.first?.doseCount ?? 1
        let log = DoseLog(timestamp: .now, doseCount: count, source: .manual, medication: med)
        ctx.insert(log)
        try? ctx.save()
        await NotificationScheduler.shared.rescheduleAll(meds: [med])
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
