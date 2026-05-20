import AppIntents
import SwiftData
import DoseCore

struct LogDoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Dose"
    static var description = IntentDescription("Log a dose of a medication.")

    @Parameter(title: "Medication") var medication: MedicationEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let id = medication.id
        guard let med = try ctx.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.id == id })).first else {
            return .result(dialog: "I couldn't find that medication.")
        }
        let count = med.schedulesArray.first?.doseCount ?? 1
        let log = DoseLog(timestamp: .now, doseCount: count, source: .manual, medication: med)
        ctx.insert(log)
        ctx.dlSave()
        await NotificationScheduler.shared.rescheduleAll(meds: [med])
        let unit = med.form.defaultUnitLabel
        let unitText = count == 1 ? unit : unit + "s"
        return .result(dialog: "Logged \(count) \(unitText) of \(med.name).")
    }
}
