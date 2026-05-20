import XCTest
@testable import DoseCore

/// PRD §edge case #4: an 08:00 dose must remain 08:00 wall-clock across DST.
/// We iterate across the US 2026 spring-forward boundary (Mar 8) and assert the
/// number of scheduled doses matches whole-day count, not whole-day count ±1.
final class DSTTests: XCTestCase {

    func test_doseCount_unaffected_by_DST_springForward() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!

        let start = cal.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 0))!
        let end   = cal.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 23, minute: 59))!

        let med = Medication(name: "DST", iconSymbol: "pills.fill", colorHex: DLAccent.sage.hex,
                              totalDoses: 100, startDate: start)
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med)
        ]

        // 15 days × 1 dose = 15 doses, regardless of the DST hop.
        let used = DoseMath.scheduledDosesUsed(med: med, from: start, to: end, calendar: cal)
        XCTAssertEqual(used, 15, "DST should not change the number of scheduled 08:00 doses")
    }
}
