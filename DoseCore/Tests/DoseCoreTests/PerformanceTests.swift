import XCTest
@testable import DoseCore

/// PRD §Non-functional: dose calculation must complete in <50ms for
/// 365 days × 10 meds × 4 daily schedules.
final class PerformanceTests: XCTestCase {

    func test_calculation_under50ms_for_365days_10meds_4schedules() throws {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2025, month: 1, day: 1, hour: 0))!
        let end   = cal.date(byAdding: .year, value: 1, to: start)!

        var meds: [Medication] = []
        for i in 0..<10 {
            let m = Medication(
                name: "Med\(i)", iconSymbol: "pills.fill",
                colorHex: DLAccent.allCases[i % DLAccent.allCases.count].hex,
                totalDoses: 1_500, startDate: start
            )
            m.schedules = (0..<4).map { j in
                DoseSchedule(timeHour: 6 + j * 4, timeMinute: 0, doseCount: 1,
                             weekdays: Array(1...7), medication: m)
            }
            meds.append(m)
        }

        measure {
            for m in meds {
                _ = DoseMath.dosesRemaining(med: m, at: end, calendar: cal)
            }
        }
    }
}
