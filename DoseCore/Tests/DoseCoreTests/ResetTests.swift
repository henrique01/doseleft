import XCTest
@testable import DoseCore

/// PRD §edge case #8: starting a new container writes a `.reset` log with
/// `doseCount = -(totalDoses - currentRemaining)` so historical math stays
/// consistent. After reset, dosesRemaining should equal totalDoses again.
final class ResetTests: XCTestCase {

    func test_reset_restoresFullContainer() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!

        let med = Medication(
            name: "Flixotide", iconSymbol: "lungs.fill", colorHex: DLAccent.lavender.hex,
            totalDoses: 120, startDate: start
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
            DoseSchedule(timeHour: 20, timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
        ]

        // 20 days in: 80 used, 40 remaining.
        let day20 = cal.date(byAdding: .day, value: 20, to: start)!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day20, calendar: cal), 40)

        // Reset: refund the 40 unused doses then move startDate forward.
        let refund = -(med.totalDoses - DoseMath.dosesRemaining(med: med, at: day20, calendar: cal))
        XCTAssertEqual(refund, -80)
        med.logs = (med.logsArray) + [DoseLog(timestamp: day20, doseCount: refund, source: .reset, medication: med)]
        // startDate is NOT changed — schedule-based math continues past the reset,
        // and the refund log brings the count back to totalDoses at the reset moment.

        // Immediately after reset: full container is back.
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day20, calendar: cal), 120)

        // 20 days after the reset: the new container has been depleted by
        // 80 scheduled doses, so 40 remain. History math stays consistent.
        let day40 = cal.date(byAdding: .day, value: 20, to: day20)!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day40, calendar: cal), 40)
    }
}
