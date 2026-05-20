import WidgetKit
import SwiftUI
import SwiftData
import DoseCore

/// Complication powered by WidgetKit. Shows the most urgent medication —
/// the one with the lowest % stock remaining — so PRN and scheduled meds
/// compete on the same axis.
struct DoseComplication: Widget {
    let kind = "DoseComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("DoseLeft")
        .description("Stock remaining for your most urgent medication.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let name: String?
    let daysLeft: Int
    let fill: Double
    let accentHex: String
    let isAsNeeded: Bool
    let dosesRemaining: Int
    let unitLabel: String
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: .now, name: "Flixotide", daysLeft: 7, fill: 0.06,
            accentHex: DLAccent.slate.hex,
            isAsNeeded: false, dosesRemaining: 14, unitLabel: "puffs"
        )
    }
    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .after(Date.now.addingTimeInterval(3600))))
    }

    private func currentEntry() -> ComplicationEntry {
        let now = Date.now
        let container = ModelContainer.doseLeftShared()
        let ctx = ModelContext(container)
        let predicate = #Predicate<Medication> { $0.isActive == true }
        let meds = (try? ctx.fetch(FetchDescriptor<Medication>(predicate: predicate))) ?? []

        let mostUrgent = meds.min { lhs, rhs in
            percentRemaining(lhs, at: now) < percentRemaining(rhs, at: now)
        }
        guard let med = mostUrgent else {
            return ComplicationEntry(
                date: now, name: nil, daysLeft: 0, fill: 0,
                accentHex: DLAccent.slate.hex,
                isAsNeeded: false, dosesRemaining: 0, unitLabel: "doses"
            )
        }

        let remaining = DoseMath.dosesRemaining(med: med, at: now)
        let days = DoseMath.daysRemaining(med: med, at: now)
        let fill = med.totalDoses > 0 ? Double(remaining) / Double(med.totalDoses) : 0
        let base = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        let unit = remaining == 1 ? base : base + "s"

        return ComplicationEntry(
            date: now, name: med.name, daysLeft: days, fill: fill,
            accentHex: med.colorHex,
            isAsNeeded: med.isAsNeeded, dosesRemaining: remaining, unitLabel: unit
        )
    }

    private func percentRemaining(_ med: Medication, at now: Date) -> Double {
        guard med.totalDoses > 0 else { return 0 }
        return Double(DoseMath.dosesRemaining(med: med, at: now)) / Double(med.totalDoses)
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        let accent = DLAccent.from(hex: entry.accentHex).color
        switch family {
        case .accessoryCircular:
            DLRing(progress: entry.fill, size: 38, stroke: 6.75, color: accent, trackColor: .white.opacity(0.2)) {
                Text("\(primaryNumber)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        case .accessoryInline:
            Text(inlineText).font(.system(.body, design: .rounded))
        default:
            DLRing(progress: entry.fill, size: 38, stroke: 6.75, color: accent, trackColor: .white.opacity(0.2)) {
                Text("\(primaryNumber)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
    }

    private var primaryNumber: Int {
        entry.isAsNeeded ? entry.dosesRemaining : entry.daysLeft
    }

    private var inlineText: String {
        guard let name = entry.name else { return "DoseLeft" }
        if entry.isAsNeeded {
            return "\(name): \(entry.dosesRemaining) \(entry.unitLabel) left"
        }
        return "\(name): \(entry.daysLeft) days left"
    }
}
