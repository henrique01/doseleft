import AppIntents
import SwiftData
import DoseCore

struct GetRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "How much is left"
    static var description = IntentDescription("Get the number of days remaining for a medication.")

    @Parameter(title: "Medication") var medication: MedicationEntity

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let id = medication.id
        guard let med = try ctx.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.id == id })).first else {
            return .result(value: 0, dialog: "I couldn't find that medication.")
        }
        let days = DoseMath.daysRemaining(med: med, at: .now)
        let phrase = days == 1 ? "About 1 day of \(med.name) left." : "About \(days) days of \(med.name) left."
        return .result(value: days, dialog: IntentDialog(stringLiteral: phrase))
    }
}
