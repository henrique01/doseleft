import WidgetKit
import SwiftData
import DoseCore

struct DoseSnapshot: Hashable {
    let id: UUID
    let name: String
    let iconSymbol: String
    let colorHex: String
    let daysLeft: Int
    let dosesRemaining: Int
    let totalDoses: Int
    let nextDoseTime: Date?
    let nextDoseCount: Int?
    let isLow: Bool
    let isAsNeeded: Bool

    var fillFraction: Double {
        guard totalDoses > 0 else { return 0 }
        return Double(dosesRemaining) / Double(totalDoses)
    }

    var unitLabel: String {
        MedicationIcon(rawValue: iconSymbol)?.defaultUnitLabel ?? "dose"
    }

    func unitLabel(count: Int) -> String {
        count == 1 ? unitLabel : unitLabel + "s"
    }
}

struct DoseEntry: TimelineEntry {
    let date: Date
    let meds: [DoseSnapshot]
}

struct DoseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoseEntry {
        DoseEntry(date: .now, meds: [Self.placeholderSnapshot])
    }

    func getSnapshot(in context: Context, completion: @escaping (DoseEntry) -> Void) {
        completion(currentEntry(now: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoseEntry>) -> Void) {
        let now = Date.now
        let cal = Calendar.current
        let snaps = fetchMeds()
        // Refresh entries: now, plus every scheduled dose time in the next 24h,
        // so the visual ticks down at 8 AM / 8 PM without an app launch.
        var refreshDates: [Date] = [now]
        for snap in snaps {
            // Use a simple heuristic: next dose time + 1 minute.
            if let next = snap.nextDoseTime, next > now {
                refreshDates.append(next.addingTimeInterval(60))
            }
        }
        // Also at midnight in case daysLeft rolls over.
        if let midnight = cal.date(bySettingHour: 0, minute: 1, second: 0, of: cal.date(byAdding: .day, value: 1, to: now)!) {
            refreshDates.append(midnight)
        }
        refreshDates.sort()

        let entries: [DoseEntry] = refreshDates.map { date in
            DoseEntry(date: date, meds: snapshotsAt(date: date))
        }
        completion(Timeline(entries: entries, policy: .after(refreshDates.last ?? now.addingTimeInterval(3600))))
    }

    private func currentEntry(now: Date) -> DoseEntry {
        DoseEntry(date: now, meds: snapshotsAt(date: now))
    }

    private func snapshotsAt(date: Date) -> [DoseSnapshot] {
        fetchMeds(at: date)
    }

    private func fetchMeds(at now: Date = .now) -> [DoseSnapshot] {
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let predicate = #Predicate<Medication> { $0.isActive == true }
        let meds = (try? ctx.fetch(FetchDescriptor<Medication>(predicate: predicate))) ?? []
        return meds
            .map { snapshot(med: $0, at: now) }
            .sorted { $0.fillFraction < $1.fillFraction }
    }

    private func snapshot(med: Medication, at now: Date) -> DoseSnapshot {
        let remaining = DoseMath.dosesRemaining(med: med, at: now)
        let days = DoseMath.daysRemaining(med: med, at: now)
        let next = DoseMath.nextDose(med: med, after: now)
        return DoseSnapshot(
            id: med.id,
            name: med.name,
            iconSymbol: med.iconSymbol,
            colorHex: med.colorHex,
            daysLeft: days,
            dosesRemaining: remaining,
            totalDoses: med.totalDoses,
            nextDoseTime: next?.date,
            nextDoseCount: next?.schedule.doseCount,
            isLow: DoseMath.isRunningLow(med: med, at: now),
            isAsNeeded: med.isAsNeeded
        )
    }

    static let placeholderSnapshot = DoseSnapshot(
        id: UUID(), name: "Flixotide", iconSymbol: "lungs.fill",
        colorHex: DLAccent.slate.hex,
        daysLeft: 7, dosesRemaining: 14, totalDoses: 120,
        nextDoseTime: .now.addingTimeInterval(3600), nextDoseCount: 2, isLow: true,
        isAsNeeded: false
    )
}
