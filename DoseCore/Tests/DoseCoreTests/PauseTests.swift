import XCTest
@testable import DoseCore

final class PauseTests: XCTestCase {

    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Med: 30 doses, one daily 8am dose. After 5 days, 25 remain. Pause at
    /// day 5. Five days later (still paused), nothing has been consumed.
    func test_pause_freezesDoseConsumption() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Test", iconSymbol: "pills.fill", colorHex: "#A78BD5",
            totalDoses: 30, startDate: start
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med),
        ]

        let day5End = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 23))!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day5End, calendar: cal), 25)

        let pauseAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 12))!
        med.pause(at: pauseAt)
        XCTAssertTrue(med.isPaused)

        // 5 days later, still paused — count should match the count at pauseAt.
        let pausedRemaining = DoseMath.dosesRemaining(med: med, at: pauseAt, calendar: cal)
        let day10 = cal.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 23))!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day10, calendar: cal), pausedRemaining)
    }

    /// While paused, `nextDose` returns nil.
    func test_pause_hidesNextDose() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Test", iconSymbol: "pills.fill", colorHex: "#A78BD5",
            totalDoses: 30, startDate: start
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med),
        ]
        let now = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 12))!
        XCTAssertNotNil(DoseMath.nextDose(med: med, after: now, calendar: cal))

        med.pause(at: now)
        XCTAssertNil(DoseMath.nextDose(med: med, after: now, calendar: cal))
    }

    /// Pause at day 5, resume at day 10 (5 days of pause). After resume, the
    /// next 5 days should bring the count down by 5 — i.e. the paused window
    /// is excluded.
    func test_resume_picksUpWhereLeftOff() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Test", iconSymbol: "pills.fill", colorHex: "#A78BD5",
            totalDoses: 30, startDate: start
        )
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 1, weekdays: Array(1...7), medication: med),
        ]

        let pauseAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: 12))!
        let pausedRemaining = DoseMath.dosesRemaining(med: med, at: pauseAt, calendar: cal)
        med.pause(at: pauseAt)

        let resumeAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 12))!
        med.resume(at: resumeAt)
        XCTAssertFalse(med.isPaused)

        // Immediately after resume: same as at pause.
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: resumeAt, calendar: cal), pausedRemaining)

        // 5 days post-resume: another ~5 daily doses consumed (every day schedule
        // makes this exact under the shift-startDate model).
        let fiveDaysLater = cal.date(byAdding: .day, value: 5, to: resumeAt)!
        XCTAssertEqual(
            DoseMath.dosesRemaining(med: med, at: fiveDaysLater, calendar: cal),
            pausedRemaining - 5
        )
    }
}
