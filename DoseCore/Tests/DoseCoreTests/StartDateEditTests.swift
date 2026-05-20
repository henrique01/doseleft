import XCTest
@testable import DoseCore

final class StartDateEditTests: XCTestCase {

    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Moving the start date earlier should make more scheduled doses count as
    /// consumed; moving it later should make fewer count.
    func test_editingStartDate_shiftsDoseMath() throws {
        let cal = makeCalendar()
        let originalStart = cal.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 0))!
        let med = Medication(
            name: "Test", iconSymbol: "pills.fill", colorHex: "#A78BD5",
            totalDoses: 60, startDate: originalStart
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med),
        ]

        let now = cal.date(from: DateComponents(year: 2026, month: 1, day: 20, hour: 23))!
        // Start Jan 10 00:00 → 8am on Jan 10, 11, ..., 20 = 11 doses consumed.
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: now, calendar: cal), 60 - 11)

        // Started 5 days earlier (Jan 5) → 16 doses consumed (Jan 5..20).
        med.startDate = cal.date(byAdding: .day, value: -5, to: originalStart)!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: now, calendar: cal), 60 - 16)

        // Started 3 days later (Jan 13) → 8 doses consumed (Jan 13..20).
        med.startDate = cal.date(byAdding: .day, value: 3, to: originalStart)!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: now, calendar: cal), 60 - 8)
    }

    /// Editing a reset log's timestamp should re-distribute the refund.
    func test_editingResetLogTimestamp_movesRefund() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Test", iconSymbol: "pills.fill", colorHex: "#A78BD5",
            totalDoses: 30, startDate: start
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med),
        ]

        // Day 10 (Jan 10 23:00): scheduled used = 10 (Jan 1..10), remaining = 20.
        // Reset refund mirrors PRD §edge case #8: -(totalDoses - remaining) = -10.
        // With refund applied at day 10, remaining = 30 - 10 - (-10) = 30.
        let day10 = cal.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 23))!
        let resetLog = DoseLog(timestamp: day10, doseCount: -10, source: .reset, medication: med)
        med.logs = [resetLog]
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day10, calendar: cal), 30)

        // Move the reset earlier to day 5 (Jan 5 23:00). The refund timestamp
        // shifts. At day 10, scheduled = 10, manual = -10, remaining = 30.
        // (Day 5 had 5 used before the reset, so the refund only "un-used" 5,
        // but the refund value itself is fixed at -10 — the test only proves
        // the timestamp move is honored without altering the value.)
        let day5 = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 23))!
        resetLog.timestamp = day5
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day10, calendar: cal), 30)

        // The behavioral difference shows at day 7: before the move, the reset
        // (at day 10) wouldn't have applied yet — but with the new timestamp
        // at day 5, the refund is already in effect at day 7.
        let day7 = cal.date(from: DateComponents(year: 2026, month: 1, day: 7, hour: 23))!
        // Day 7: scheduled = 7, manual = -10 (reset at day 5 counts). 30 - 7 + 10 = 33.
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day7, calendar: cal), 33)
    }
}
