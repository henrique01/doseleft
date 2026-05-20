import SwiftUI
import WidgetKit
import DoseCore

struct LockRectangularView: View {
    let entry: DoseEntry

    var body: some View {
        if let m = entry.meds.first {
            HStack(spacing: 10) {
                DLRing(progress: m.fillFraction, size: 40, stroke: 3, color: .white, trackColor: .white.opacity(0.2)) {
                    Text("\(m.isAsNeeded ? m.dosesRemaining : m.daysLeft)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(m.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(subtitle(for: m))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        } else {
            Text("No medications").font(.system(size: 13)).foregroundStyle(.white)
        }
    }

    private func subtitle(for m: DoseSnapshot) -> String {
        if m.isAsNeeded {
            return "\(m.dosesRemaining) \(m.unitLabel(count: m.dosesRemaining)) left"
        }
        return "\(m.daysLeft) days · \(m.dosesRemaining) \(m.unitLabel(count: m.dosesRemaining))"
    }
}

#if DEBUG
#Preview(as: .accessoryRectangular) {
    DoseWidget()
} timeline: {
    DoseEntry(date: .now, meds: [DoseTimelineProvider.placeholderSnapshot])
}
#endif
