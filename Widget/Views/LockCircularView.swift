import SwiftUI
import WidgetKit
import DoseCore

struct LockCircularView: View {
    let entry: DoseEntry

    var body: some View {
        if let m = entry.meds.first {
            DLRing(progress: m.fillFraction, size: 50, stroke: 3,
                   color: .white,
                   trackColor: .white.opacity(0.2)) {
                VStack(spacing: 0) {
                    Text("\(m.isAsNeeded ? m.dosesRemaining : m.daysLeft)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(m.isAsNeeded ? String(m.unitLabel.prefix(1)) : "d")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        } else {
            Image(systemName: "pills.fill").font(.system(size: 22)).foregroundStyle(.white)
        }
    }
}

#if DEBUG
#Preview(as: .accessoryCircular) {
    DoseWidget()
} timeline: {
    DoseEntry(date: .now, meds: [DoseTimelineProvider.placeholderSnapshot])
}
#endif
