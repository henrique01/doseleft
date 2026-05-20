import Foundation
import SwiftData

@Model
public final class DoseSchedule {
    public var id: UUID = UUID()
    public var timeHour: Int = 8
    public var timeMinute: Int = 0
    public var doseCount: Int = 1
    /// Calendar weekday integers (1=Sun … 7=Sat) when this dose time applies.
    public var weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    public var medication: Medication?

    public init(
        id: UUID = UUID(),
        timeHour: Int,
        timeMinute: Int = 0,
        doseCount: Int = 1,
        weekdays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        medication: Medication? = nil
    ) {
        self.id = id
        self.timeHour = timeHour
        self.timeMinute = timeMinute
        self.doseCount = doseCount
        self.weekdays = weekdays
        self.medication = medication
    }

    public var isEveryDay: Bool {
        Set(weekdays) == Set(1...7)
    }
}
