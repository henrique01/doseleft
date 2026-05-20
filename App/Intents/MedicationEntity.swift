import AppIntents
import SwiftData
import DoseCore

/// AppIntent-facing entity that wraps a `Medication` for Siri / Shortcuts.
struct MedicationEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Medication"
    static var defaultQuery = MedicationEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct MedicationEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [MedicationEntity] {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let meds = try ctx.fetch(FetchDescriptor<Medication>(predicate: #Predicate { identifiers.contains($0.id) }))
        return meds.map { MedicationEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let meds = try ctx.fetch(FetchDescriptor<Medication>(predicate: #Predicate { $0.isActive == true }))
        return meds.map { MedicationEntity(id: $0.id, name: $0.name) }
    }
}
