import SwiftUI
import DoseCore

/// Home-list row, 80pt tall, no card container — flat with a 0.5pt separator
/// drawn by the parent. Matches the design's `DLMedRow`.
struct MedRow: View {
    let med: Medication
    let daysLeft: Int
    let dosesRemaining: Int
    let nextDose: (date: Date, count: Int)?
    let isLow: Bool

    private var accent: Color { DLAccent.from(hex: med.colorHex).color }

    private var fillFraction: Double {
        guard med.totalDoses > 0 else { return 0 }
        return Double(dosesRemaining) / Double(med.totalDoses)
    }

    var body: some View {
        HStack(spacing: 14) {
            MedBadge(symbol: med.iconSymbol, accent: accent)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(med.name)
                        .font(DL.Text.headline17)
                        .foregroundStyle(DL.text)
                        .lineLimit(1)
                    if med.isPaused {
                        DoseChip(title: "Paused", accent: accent)
                    } else if isLow {
                        DoseChip(title: "Running low", accent: accent)
                    }
                }
                Text(subtitleText)
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                statsColumn
                DLRing(progress: fillFraction, size: 36, stroke: 3, color: accent) { EmptyView() }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 80)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var statsColumn: some View {
        if med.isAsNeeded {
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(dosesRemaining)")
                    .font(DL.Numerals.title28)
                    .foregroundStyle(DL.text)
                Text("\(unitLabel(for: dosesRemaining)) left")
                    .font(DL.Text.caption11)
                    .foregroundStyle(DL.text2)
            }
        } else {
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(daysLeft)")
                    .font(DL.Numerals.title28)
                    .foregroundStyle(DL.text)
                Text("days left")
                    .font(DL.Text.caption11)
                    .foregroundStyle(DL.text2)
                Text("\(dosesRemaining) \(unitLabel(for: dosesRemaining))")
                    .font(DL.Text.caption11)
                    .foregroundStyle(DL.text2)
            }
        }
    }

    private var subtitleText: String {
        if med.isPaused { return "Schedule paused" }
        guard let next = nextDose else { return "No upcoming doses" }
        let formatter = Date.FormatStyle.dateTime.hour().minute()
        return "Next dose \(next.date.formatted(formatter)) · \(next.count) \(unitLabel(for: next.count))"
    }

    private func unitLabel(for count: Int) -> String {
        let base = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        return count == 1 ? base : base + "s"
    }

    private var accessibilityLabel: String {
        var parts: [String] = [med.name]
        if med.isAsNeeded {
            parts.append("\(dosesRemaining) \(unitLabel(for: dosesRemaining)) left")
        } else {
            parts.append("\(daysLeft) days left")
            parts.append("\(dosesRemaining) \(unitLabel(for: dosesRemaining))")
        }
        if med.isPaused { parts.append("paused") }
        else if isLow { parts.append("running low") }
        if let next = nextDose {
            parts.append("next dose \(next.date.formatted(.dateTime.hour().minute())), \(next.count) \(unitLabel(for: next.count))")
        }
        return parts.joined(separator: ", ")
    }
}
