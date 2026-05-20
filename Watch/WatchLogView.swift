import SwiftUI
import SwiftData
import DoseCore

struct WatchLogView: View {
    @Bindable var med: Medication
    @Environment(\.modelContext) private var ctx

    private enum LastAction { case dose, missed }
    @State private var logged = false
    @State private var lastAction: LastAction = .dose

    private var accent: Color { DLAccent.from(hex: med.colorHex).color }
    private var remaining: Int { DoseMath.dosesRemaining(med: med, at: .now) }
    private var isAutomatic: Bool { med.trackingMode == .automatic }

    var body: some View {
        VStack(spacing: 14) {
            if logged {
                confirmation
            } else {
                detailContent
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var detailContent: some View {
        VStack(spacing: 10) {
            Text(med.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
            DLRing(progress: med.totalDoses > 0 ? Double(remaining) / Double(med.totalDoses) : 0,
                   size: 72, stroke: 7, color: accent, trackColor: .white.opacity(0.12)) {
                Text("\(remaining)").font(.system(size: 24, weight: .bold, design: .rounded))
            }
            Text("\(remaining) of \(med.totalDoses) left").font(.system(size: 11)).foregroundStyle(.secondary)
            Button(action: log) {
                Text(isAutomatic ? "Log extra" : "Log dose")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            if isAutomatic {
                let canMiss = MissedDosePlanning.canLogMissed(for: med)
                Button(action: logMissed) {
                    Text("Missed today")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!canMiss)
                .opacity(canMiss ? 1 : 0.5)
            }
        }
    }

    private var confirmation: some View {
        VStack(spacing: 10) {
            Text(med.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
            ZStack {
                Circle().fill(accent).frame(width: 56, height: 56)
                Image(systemName: lastAction == .missed ? "exclamationmark" : "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            if lastAction == .missed {
                Text("Marked missed").font(.system(size: 14, weight: .bold))
            } else {
                let count = med.schedulesArray.first?.doseCount ?? 1
                let unit = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
                Text("Logged \(count) \(count == 1 ? unit : unit + "s")")
                    .font(.system(size: 14, weight: .bold))
            }
            HStack(spacing: 4) {
                Text("\(remaining)").font(.system(size: 14, weight: .bold, design: .rounded))
                Text("left").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func log() {
        let count = med.schedulesArray.first?.doseCount ?? 1
        let entry = DoseLog(timestamp: .now, doseCount: count, source: .manual, medication: med)
        ctx.insert(entry)
        ctx.dlSave()
        lastAction = .dose
        withAnimation { logged = true }
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
    }

    private func logMissed() {
        guard let target = MissedDosePlanning.eligibleMissedDose(for: med) else { return }
        let entry = DoseLog(
            timestamp: target.when,
            doseCount: -target.doseCount,
            source: .missed,
            medication: med
        )
        ctx.insert(entry)
        ctx.dlSave()
        lastAction = .missed
        withAnimation { logged = true }
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
    }
}

#if DEBUG
private struct WatchLogPreviewHost: View {
    let med: Medication
    let container: ModelContainer
    init(_ build: () -> Medication) {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        let ctx = ModelContext(c)
        let m = build()
        ctx.insert(m)
        m.schedules?.forEach { ctx.insert($0) }
        try? ctx.save()
        self.med = m
        self.container = c
    }
    var body: some View {
        NavigationStack { WatchLogView(med: med) }
            .modelContainer(container)
    }
}

#Preview("Scheduled") {
    WatchLogPreviewHost { PreviewFixtures.scheduledMed() }
}

#Preview("As-needed") {
    WatchLogPreviewHost { PreviewFixtures.asNeededMed() }
}
#endif
