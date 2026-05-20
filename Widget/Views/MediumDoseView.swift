import SwiftUI
import WidgetKit
import AppIntents
import DoseCore

struct MediumDoseView: View {
    let entry: DoseEntry

    var body: some View {
        let meds = Array(entry.meds.prefix(3))
        VStack(alignment: .leading, spacing: 0) {
            Text("DOSELEFT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(DL.text2)
                .padding(.bottom, 6)
            ForEach(Array(meds.enumerated()), id: \.element.id) { idx, m in
                if idx > 0 { Divider() }
                row(for: m)
            }
            if meds.isEmpty {
                Spacer()
                Text("Add a medication to see it here.").font(.system(size: 12)).foregroundStyle(DL.text2)
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }

    private func row(for m: DoseSnapshot) -> some View {
        let accent = DLAccent.from(hex: m.colorHex).color
        return HStack(spacing: 10) {
            Circle().fill(accent).frame(width: 26, height: 26)
                .overlay(Image(systemName: m.iconSymbol).font(.system(size: 13, weight: .medium)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 1) {
                Text(m.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                if let next = m.nextDoseTime, let count = m.nextDoseCount {
                    Text("Next \(next.formatted(.dateTime.hour().minute())) · \(count)")
                        .font(.system(size: 11))
                        .foregroundStyle(DL.text2)
                        .lineLimit(1)
                } else if m.isAsNeeded {
                    Text("As needed")
                        .font(.system(size: 11))
                        .foregroundStyle(DL.text2)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            statsColumn(for: m)
            // Tap to log a dose via the widget intent.
            Button(intent: WidgetLogDoseIntent(medicationID: m.id.uuidString)) {
                DLRing(progress: m.fillFraction, size: 22, stroke: 2.2, color: accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log dose for \(m.name)")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statsColumn(for m: DoseSnapshot) -> some View {
        if m.isAsNeeded {
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(m.dosesRemaining)").font(.system(size: 18, weight: .bold, design: .rounded))
                Text(m.unitLabel(count: m.dosesRemaining).uppercased())
                    .font(.system(size: 9, weight: .semibold)).tracking(0.2).foregroundStyle(DL.text2)
            }
        } else {
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(m.daysLeft)").font(.system(size: 18, weight: .bold, design: .rounded))
                Text("DAYS").font(.system(size: 9, weight: .semibold)).tracking(0.2).foregroundStyle(DL.text2)
                Text("\(m.dosesRemaining) \(m.unitLabel(count: m.dosesRemaining))")
                    .font(.system(size: 9)).foregroundStyle(DL.text2)
            }
        }
    }
}
