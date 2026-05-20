import AppIntents
import SwiftData
import DoseCore

struct LogMissedIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Dose as Missed"
    static var description = IntentDescription("Log that you missed today's scheduled dose of a medication.")

    @Parameter(title: "Medication") var medication: MedicationEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let id = medication.id
        guard let med = try ctx.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.id == id })).first else {
            return .result(dialog: "I couldn't find that medication.")
        }
        let inserted = DoseLogActions.logMissed(for: med, in: ctx)
        if inserted {
            return .result(dialog: "Marked \(med.name) as missed today.")
        } else {
            return .result(dialog: "No scheduled dose for \(med.name) has come due today.")
        }
    }
}
