import Foundation
import SwiftData

@Model
public final class DoseLog {
    public var id: UUID = UUID()
    public var timestamp: Date = Date()
    /// Positive = doses used. Negative = correction / reset.
    public var doseCount: Int = 0
    public var sourceRaw: String = LogSource.manual.rawValue
    public var medication: Medication?

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        doseCount: Int,
        source: LogSource = .manual,
        medication: Medication? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.doseCount = doseCount
        self.sourceRaw = source.rawValue
        self.medication = medication
    }

    public var source: LogSource {
        get { LogSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
