import XCTest
import SwiftData
@testable import DoseCore

final class DoseMathTests: XCTestCase {

    // PRD §Acceptance criteria #1: 4 puffs/day × 120 doses → 30 days,
    // computed without any timer ticks.
    func test_120doses_4perDay_emptiesIn30Days() throws {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0, minute: 0))!

        let med = Medication(
            name: "Flixotide",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.lavender.hex,
            totalDoses: 120,
            startDate: start,
            trackingMode: .automatic
        )
        med.schedules = [
            DoseSchedule(timeHour: 8,  timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
            DoseSchedule(timeHour: 20, timeMinute: 0, doseCount: 2, weekdays: Array(1...7), medication: med),
        ]

        // 1 day after start: 4 doses used, 116 remaining.
        let day1 = cal.date(byAdding: .day, value: 1, to: start)!
        XCTAssertEqual(DoseMath.scheduledDosesUsed(med: med, from: start, to: day1, calendar: cal), 4)
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day1, calendar: cal), 116)

        // 30 days after start: 120 used, 0 remaining.
        let day30 = cal.date(byAdding: .day, value: 30, to: start)!
        XCTAssertEqual(DoseMath.scheduledDosesUsed(med: med, from: start, to: day30, calendar: cal), 120)
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day30, calendar: cal), 0)

        // Long absence (60 days): clamped to 0, not negative.
        let day60 = cal.date(byAdding: .day, value: 60, to: start)!
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: day60, calendar: cal), 0)
    }

    func test_dailyDoseRate() {
        let med = Medication(name: "X", iconSymbol: "pills.fill", colorHex: DLAccent.sage.hex, totalDoses: 30)
        med.schedules = [
            DoseSchedule(timeHour: 8, doseCount: 1, weekdays: Array(1...7), medication: med),  // 7/wk
            DoseSchedule(timeHour: 20, doseCount: 2, weekdays: Array(1...5), medication: med), // 10/wk
        ]
        XCTAssertEqual(DoseMath.dailyDoseRate(med: med), Double(17) / 7.0, accuracy: 0.001)
    }

    func test_isRunningLow_atLeadDays() throws {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Singulair", iconSymbol: "pills.fill", colorHex: DLAccent.sage.hex,
            totalDoses: 30, startDate: start, reminderLeadDays: 7
        )
        med.schedules = [DoseSchedule(timeHour: 9, doseCount: 1, weekdays: Array(1...7), medication: med)]
        // 23 days in → 7 doses remaining = 7 days. isRunningLow should be true.
        let day23 = cal.date(byAdding: .day, value: 23, to: start)!
        XCTAssertTrue(DoseMath.isRunningLow(med: med, at: day23, calendar: cal))
        // 22 days in → 8 remaining = 8 days. Not yet low.
        let day22 = cal.date(byAdding: .day, value: 22, to: start)!
        XCTAssertFalse(DoseMath.isRunningLow(med: med, at: day22, calendar: cal))
    }

    func test_isRunningLow_asNeeded_usesDoseThreshold() throws {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 0))!
        let med = Medication(
            name: "Ventolin",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.sage.hex,
            totalDoses: 10,
            startDate: start,
            trackingMode: .manual,
            isAsNeeded: true,
            reminderLeadDoses: 3
        )
        // No schedules — rescue med. Above threshold: 10 left.
        XCTAssertFalse(DoseMath.isRunningLow(med: med, at: start, calendar: cal))

        // Burn down to exactly the threshold via manual logs.
        for _ in 0..<7 {
            med.logs = (med.logs ?? []) + [DoseLog(timestamp: start, doseCount: 1, source: .manual, medication: med)]
        }
        XCTAssertEqual(DoseMath.dosesRemaining(med: med, at: start, calendar: cal), 3)
        XCTAssertTrue(DoseMath.isRunningLow(med: med, at: start, calendar: cal))
    }

    func test_projectedEndDate_asNeeded_returnsNil() {
        let med = Medication(
            name: "Ventolin",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.sage.hex,
            totalDoses: 10,
            trackingMode: .manual,
            isAsNeeded: true
        )
        XCTAssertNil(DoseMath.projectedEndDate(med: med, at: .now))
    }

    func test_nextDose_findsTomorrowWhenScheduledOnTuesdays() throws {
        let cal = Calendar(identifier: .gregorian)
        // 2026-05-19 is a Tuesday.
        let tuesdayNoon = cal.date(from: DateComponents(year: 2026, month: 5, day: 19, hour: 12))!
        let med = Medication(name: "T", iconSymbol: "pills.fill", colorHex: DLAccent.sage.hex, totalDoses: 10, startDate: tuesdayNoon)
        // Tue evening and Thu morning.
        med.schedules = [
            DoseSchedule(timeHour: 20, timeMinute: 0, doseCount: 1, weekdays: [3], medication: med),
            DoseSchedule(timeHour: 8,  timeMinute: 0, doseCount: 1, weekdays: [5], medication: med),
        ]
        let next = DoseMath.nextDose(med: med, after: tuesdayNoon, calendar: cal)
        XCTAssertNotNil(next)
        let comps = cal.dateComponents([.weekday, .hour], from: next!.date)
        XCTAssertEqual(comps.weekday, 3) // Tuesday
        XCTAssertEqual(comps.hour, 20)
    }
}
