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
                DLRing(progress: fillFraction, size: 36, stroke: 7, color: accent) { EmptyView() }
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
                Text("\(doseLabel(for: dosesRemaining)) left")
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
                Text("\(dosesRemaining) \(doseLabel(for: dosesRemaining))")
                    .font(DL.Text.caption11)
                    .foregroundStyle(DL.text2)
            }
        }
    }

    /// Label for a count of full doses (e.g. dosesRemaining). Click pens
    /// always show "dose"/"doses" here — the click count belongs on the
    /// schedule subtitle, not on the remaining-doses stat.
    private func doseLabel(for count: Int) -> String {
        if med.isClickPen { return count == 1 ? "dose" : "doses" }
        return unitLabel(for: count)
    }

    private var subtitleText: String {
        if med.isPaused { return "Schedule paused" }
        guard let next = nextDose else { return "No upcoming doses" }
        let formatter = Date.FormatStyle.dateTime.hour().minute()
        let displayCount = displayCount(forScheduleCount: next.count)
        return "Next dose \(next.date.formatted(formatter)) · \(displayCount) \(unitLabel(for: displayCount))"
    }

    /// Click pens display scheduled-dose counts in clicks (count × clicksPerDose),
    /// matching how the user actually dials them. Other meds use the raw count.
    private func displayCount(forScheduleCount count: Int) -> Int {
        med.isClickPen ? count * med.clicksPerDose : count
    }

    private func unitLabel(for count: Int) -> String {
        let base = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        return count == 1 ? base : base + "s"
    }

    private var accessibilityLabel: String {
        var parts: [String] = [med.name]
        if med.isAsNeeded {
            parts.append("\(dosesRemaining) \(doseLabel(for: dosesRemaining)) left")
        } else {
            parts.append("\(daysLeft) days left")
            parts.append("\(dosesRemaining) \(doseLabel(for: dosesRemaining))")
        }
        if med.isPaused { parts.append("paused") }
        else if isLow { parts.append("running low") }
        if let next = nextDose {
            let displayCount = displayCount(forScheduleCount: next.count)
            parts.append("next dose \(next.date.formatted(.dateTime.hour().minute())), \(displayCount) \(unitLabel(for: displayCount))")
        }
        return parts.joined(separator: ", ")
    }
}
