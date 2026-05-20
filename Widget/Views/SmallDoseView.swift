import SwiftUI
import WidgetKit
import DoseCore

struct SmallDoseView: View {
    let entry: DoseEntry

    var body: some View {
        if let m = entry.meds.first {
            let accent = DLAccent.from(hex: m.colorHex).color
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(accent).frame(width: 18, height: 18)
                        .overlay(Image(systemName: m.iconSymbol).font(.system(size: 10, weight: .medium)).foregroundStyle(.white))
                    Text(m.name).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                    Spacer()
                }
                DLRing(progress: m.fillFraction, size: 94, stroke: 4, color: accent) {
                    ringContent(for: m)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            empty
        }
    }

    @ViewBuilder
    private func ringContent(for m: DoseSnapshot) -> some View {
        if m.isAsNeeded {
            VStack(spacing: 2) {
                Text("\(m.dosesRemaining)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DL.text)
                Text(m.unitLabel(count: m.dosesRemaining).uppercased() + " LEFT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.2)
                    .foregroundStyle(DL.text2)
            }
        } else {
            VStack(spacing: 1) {
                Text("\(m.daysLeft)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(DL.text)
                Text("DAYS LEFT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.2)
                    .foregroundStyle(DL.text2)
                Text("\(m.dosesRemaining) \(m.unitLabel(count: m.dosesRemaining))")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(DL.text2)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills.fill").font(.system(size: 28)).foregroundStyle(DL.Light.tertiary)
            Text("No medications").font(.system(size: 11)).foregroundStyle(DL.text2)
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    DoseWidget()
} timeline: {
    DoseEntry(date: .now, meds: [DoseTimelineProvider.placeholderSnapshot])
    DoseEntry(date: .now, meds: [])
}
#endif
