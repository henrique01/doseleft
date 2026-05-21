import XCTest
@testable import DoseCore

final class FinishedDateTests: XCTestCase {

    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func scheduledMed(totalDoses: Int, start: Date) -> Medication {
        let med = Medication(
            name: "Flixotide", iconSymbol: "lungs.fill", colorHex: DLAccent.lavender.hex,
            totalDoses: totalDoses, startDate: start
        )
        // 4 doses/day: 8am ×2, 8pm ×2 — matches existing fixture patterns.
        med.schedules = [
            DoseSchedule(timeHour: 8, timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
            DoseSchedule(timeHour: 20, timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
        ]
        return med
    }

    func test_finishedDate_nilWhenRemainingPositive() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        let day1 = cal.date(byAdding: .day, value: 1, to: start)!
        XCTAssertNil(DoseMath.finishedDate(med: med, at: day1, calendar: cal))
    }

    func test_finishedDate_atScheduledExhaustion() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        // 120 doses / 4 per day = 30 days. Day 30, 20:00 dose is the 120th.
        let day31 = cal.date(byAdding: .day, value: 31, to: start)!
        let expected = cal.date(from: DateComponents(year: 2026, month: 1, day: 30, hour: 20, minute: 0))!
        XCTAssertEqual(DoseMath.finishedDate(med: med, at: day31, calendar: cal), expected)
    }

    func test_finishedDate_asNeededViaManualLogs() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Ventolin", iconSymbol: "lungs.fill", colorHex: DLAccent.terracotta.hex,
            totalDoses: 5, startDate: start, isAsNeeded: true
        )

        var logs: [DoseLog] = []
        var lastTimestamp: Date = start
        for i in 1...5 {
            let when = cal.date(byAdding: .hour, value: i * 6, to: start)!
            logs.append(DoseLog(timestamp: when, doseCount: 1, source: .manual, medication: med))
            lastTimestamp = when
        }
        med.logs = logs

        let queryAt = cal.date(byAdding: .day, value: 3, to: start)!
        XCTAssertEqual(DoseMath.finishedDate(med: med, at: queryAt, calendar: cal), lastTimestamp)
    }

    func test_finishedDate_pausedBeforeFinish() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        // Pause well before exhaustion.
        let pauseAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 12))!
        med.pause(at: pauseAt)

        // Even querying way after, finish is nil (still has stock and paused).
        let day100 = cal.date(byAdding: .day, value: 100, to: start)!
        XCTAssertNil(DoseMath.finishedDate(med: med, at: day100, calendar: cal))
    }

    func test_finishedDate_resetsClearFinish() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        // Reset the day after exhaustion. The refund restores 0 remaining (it
        // was already 0) but the reset boundary clears the prior finish.
        let resetAt = cal.date(from: DateComponents(year: 2026, month: 2, day: 1, hour: 12))!
        med.logs = [DoseLog(timestamp: resetAt, doseCount: -0, source: .reset, medication: med)]
        // doseCount = -0 is fine for this case because the prior container had
        // already hit zero before the reset. The reset still resets the walk.
        // Need explicit refund for dosesRemaining to be > 0 after reset:
        let remainingAtReset = DoseMath.dosesRemaining(med: med, at: resetAt, calendar: cal)
        let refund = -(med.totalDoses - remainingAtReset)
        med.logs = [DoseLog(timestamp: resetAt, doseCount: refund, source: .reset, medication: med)]

        let dayAfterReset = cal.date(byAdding: .hour, value: 1, to: resetAt)!
        // After reset there are doses again, so dosesRemaining > 0 and the
        // early guard returns nil.
        XCTAssertNil(DoseMath.finishedDate(med: med, at: dayAfterReset, calendar: cal))
    }

    func test_finishedDate_priorFinishIgnoredAfterReset_thenRefinishes() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        // Exhaust day 30. Reset day 31. Run another 30 days, then exhaust again.
        let resetAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12))!
        let remainingAtReset = DoseMath.dosesRemaining(med: med, at: resetAt, calendar: cal)
        let refund = -(med.totalDoses - remainingAtReset)
        med.logs = [DoseLog(timestamp: resetAt, doseCount: refund, source: .reset, medication: med)]

        // 30 more days of 4/day consumes 120 doses again. Query well past.
        let queryAt = cal.date(byAdding: .day, value: 60, to: resetAt)!
        let finish = DoseMath.finishedDate(med: med, at: queryAt, calendar: cal)
        XCTAssertNotNil(finish)
        // Finish should be AFTER the reset, not the prior finish at day 30.
        XCTAssertGreaterThan(finish!, resetAt)
    }

    func test_finishedDate_correctionLogTipsIntoFinish() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        // 121 total, will reach 119 used by end of day 30. A +1 correction
        // log pushes to 120 (= total), so that log's timestamp is the finish.
        let med = scheduledMed(totalDoses: 121, start: start)

        let correctionAt = cal.date(from: DateComponents(year: 2026, month: 1, day: 30, hour: 22, minute: 30))!
        // Use a +2 correction to be sure we cross 121 regardless of rounding —
        // day-30 20:00 dose puts cumulative at 120, +2 = 122 ≥ 121.
        med.logs = [DoseLog(timestamp: correctionAt, doseCount: 2, source: .correction, medication: med)]

        let queryAt = cal.date(byAdding: .day, value: 5, to: correctionAt)!
        XCTAssertEqual(DoseMath.finishedDate(med: med, at: queryAt, calendar: cal), correctionAt)
    }

    func test_finishedDate_longAbsence() throws {
        let cal = makeCalendar()
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = scheduledMed(totalDoses: 120, start: start)

        // App opened 100 days later. Finish should still be the day-30 20:00 event.
        let day100 = cal.date(byAdding: .day, value: 100, to: start)!
        let expected = cal.date(from: DateComponents(year: 2026, month: 1, day: 30, hour: 20, minute: 0))!
        XCTAssertEqual(DoseMath.finishedDate(med: med, at: day100, calendar: cal), expected)
    }
}
