import SwiftUI
import SwiftData
import WidgetKit
import DoseCore

struct MedicationDetailView: View {
    @Bindable var med: Medication
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showHistory = false
    @State private var editingLog: DoseLog?

    private var accent: Color { DLAccent.from(hex: med.colorHex).color }
    private var remaining: Int { DoseMath.dosesRemaining(med: med, at: .now) }
    private var daysLeft: Int { DoseMath.daysRemaining(med: med, at: .now) }
    private var isLow: Bool { !med.isPaused && DoseMath.isRunningLow(med: med, at: .now) }
    private var fillFraction: Double {
        guard med.totalDoses > 0 else { return 0 }
        return Double(remaining) / Double(med.totalDoses)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLow {
                    runningLowBanner.padding(.horizontal, 16).padding(.top, 4)
                }
                heroRing.padding(.top, 24)
                titleBlock.padding(.top, 18)
                actionButton.padding(.horizontal, 20).padding(.top, 20)
                scheduleSection.padding(.top, 20)
                activitySection.padding(.top, 20)
                containerSection.padding(.top, 20).padding(.bottom, 40)
            }
        }
        .background(DL.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }.foregroundStyle(accent)
            }
        }
        .sheet(isPresented: $showEdit) { MedicationEditView(existing: med) }
        .sheet(isPresented: $showHistory) { HistoryView(med: med) }
        .sheet(item: $editingLog) { log in
            EditLogDateSheet(log: log, accent: accent) { newDate in
                DoseLogActions.updateTimestamp(log, to: newDate, for: med, in: context)
            }
        }
    }

    // MARK: - Sections

    private var runningLowBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.system(size: 16))
                .foregroundStyle(accent.dlSaturated())
            VStack(alignment: .leading, spacing: 1) {
                Text("Running low — refill soon")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent.dlSaturated())
                Text(med.isAsNeeded
                     ? "Only \(remaining) \(unitLabel(for: remaining)) left."
                     : "About \(daysLeft) days remaining at current schedule.")
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(accent.opacity(0.4), lineWidth: 0.5))
    }

    private var heroRing: some View {
        DLRing(progress: fillFraction, size: 200, stroke: 11, color: accent) {
            VStack(spacing: 6) {
                Text("\(med.isAsNeeded ? remaining : daysLeft)")
                    .font(DL.Numerals.display(80, weight: .bold))
                    .foregroundStyle(DL.text)
                Text(med.isAsNeeded ? unitLabel(for: remaining) + " left" : "days left")
                    .font(DL.Text.subhead15)
                    .foregroundStyle(DL.text2)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(med.name)
                .font(DL.Text.title22)
                .foregroundStyle(DL.text)
            HStack(spacing: 0) {
                Text("\(remaining)").font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(" of ")
                Text("\(med.totalDoses)").font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(" doses remaining")
            }
            .font(DL.Text.subhead15)
            .foregroundStyle(DL.text2)
            if let pausedAt = med.pausedAt {
                Text("Paused since \(pausedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(DL.Text.footnote13)
                    .foregroundStyle(accent.dlSaturated())
                    .padding(.top, 4)
            }
        }
    }

    private var actionButton: some View {
        Group {
            if med.isPaused && !med.isAsNeeded {
                PrimaryButton(title: "Resume schedule", accent: accent, action: resumeMedication)
            } else if med.trackingMode == .manual {
                PrimaryButton(title: "Log dose", accent: accent, action: logDose)
            } else {
                VStack(spacing: 10) {
                    PrimaryButton(title: "I missed today", accent: accent, action: logMissed)
                        .disabled(!canLogMissed)
                        .opacity(canLogMissed ? 1 : 0.5)
                    SecondaryButton(title: "Log extra dose", action: logExtraDose)
                }
            }
        }
    }

    private var canLogMissed: Bool {
        DoseLogActions.canLogMissed(for: med)
    }

    @ViewBuilder
    private var scheduleSection: some View {
        if med.isAsNeeded {
            VStack(spacing: 0) {
                sectionHeader("Schedule")
                groupContainer {
                    HStack {
                        Text("As needed (rescue)")
                            .font(DL.Text.body17)
                            .foregroundStyle(DL.text2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                }
            }
        } else {
            VStack(spacing: 0) {
                sectionHeader("Schedule")
                groupContainer {
                    let scheds = med.schedulesArray
                    ForEach(Array(scheds.enumerated()), id: \.element.id) { idx, sched in
                        scheduleRow(sched)
                        if idx < scheds.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    private func scheduleRow(_ schedule: DoseSchedule) -> some View {
        // Click pens render the count in clicks (count × clicksPerDose), and
        // use the icon's "click" unit; non-pens use the regular unit label.
        let isPen = med.isClickPen
        let displayCount = isPen ? schedule.doseCount * med.clicksPerDose : schedule.doseCount
        let unit = isPen
            ? (displayCount == 1 ? "click" : "clicks")
            : unitLabel(for: displayCount)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(timeString(schedule)).font(DL.Numerals.row17).foregroundStyle(DL.text)
                    Text("· \(displayCount) \(unit)")
                        .font(DL.Text.body17).foregroundStyle(DL.text2)
                }
                Text(weekdayText(schedule))
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DL.text3)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }

    private var activitySection: some View {
        VStack(spacing: 0) {
            sectionHeader("Recent activity")
            groupContainer {
                let presentation = MedicationLogPresentation.resolve(for: med, includeSynthetic: true)
                let combined = presentation.synthetic + presentation.realLogs
                let recent = Array(combined.sorted { $0.timestamp > $1.timestamp }.prefix(3))
                if recent.isEmpty {
                    HStack {
                        Text("No activity yet").font(DL.Text.body17).foregroundStyle(DL.text2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { idx, log in
                        ActivityRow(
                            timestamp: log.timestamp,
                            displayText: logDisplay(log),
                            source: log.source,
                            accent: accent
                        )
                        .contextMenu {
                            if log.source == .reset {
                                Button { editingLog = log } label: {
                                    Label("Edit date", systemImage: "calendar")
                                }
                            }
                            Button(role: .destructive) {
                                DoseLogActions.erase(log, for: med, in: context)
                            } label: {
                                Label("Erase", systemImage: "trash")
                            }
                        }
                        if idx < recent.count - 1 { Divider().padding(.leading, 16) }
                    }
                }
            }
            HStack {
                Button("View all") { showHistory = true }
                    .font(DL.Text.subhead15)
                    .foregroundStyle(accent)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    private var containerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Container")
            groupContainer {
                infoRow("Started", value: startedDisplay.formatted(date: .abbreviated, time: .omitted))
                Divider().padding(.leading, 16)
                infoRow("Total doses", value: "\(med.totalDoses)", valueRounded: true)
                if med.isClickPen {
                    Divider().padding(.leading, 16)
                    infoRow("Dose",
                            value: "\(formatPenMg(med.doseMg)) mg (\(med.clicksPerDose) clicks)",
                            valueRounded: true)
                    Divider().padding(.leading, 16)
                    let perClick = med.clicksPerDose > 0 ? med.doseMg / Double(med.clicksPerDose) : 0
                    infoRow("Per click", value: "\(formatPenMg(perClick)) mg", valueRounded: true)
                }
                Divider().padding(.leading, 16)
                Button(action: startNewContainer) {
                    HStack {
                        Text("Start new container")
                            .font(DL.Text.body17)
                            .foregroundStyle(accent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                if !med.isAsNeeded {
                    Divider().padding(.leading, 16)
                    Button(action: togglePause) {
                        HStack {
                            Text(med.isPaused ? "Resume schedule" : "Pause schedule")
                                .font(DL.Text.body17)
                                .foregroundStyle(accent)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(DL.text2)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func groupContainer<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0, content: content)
            .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
    }

    private func infoRow(_ label: String, value: String, valueRounded: Bool = false) -> some View {
        HStack {
            Text(label).font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            Text(value)
                .font(valueRounded ? DL.Numerals.row17 : DL.Text.subhead15)
                .foregroundStyle(DL.text2)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }

    private func timeString(_ s: DoseSchedule) -> String {
        var comps = DateComponents(); comps.hour = s.timeHour; comps.minute = s.timeMinute
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }

    private func formatPenMg(_ value: Double) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.3f", value)
    }

    private func unitLabel(for count: Int) -> String {
        // For click pens, integer counts in the detail view refer to doses,
        // not clicks (clicks are derived for schedule rows specifically).
        // Show "dose"/"doses" so the running-low banner and hero ring stay
        // legible — schedule rows already do their own click conversion.
        if med.isClickPen { return count == 1 ? "dose" : "doses" }
        let base = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        return count == 1 ? base : base + "s"
    }

    private func weekdayText(_ s: DoseSchedule) -> String {
        s.isEveryDay ? "Every day" : weekdayList(s.weekdays)
    }

    private func weekdayList(_ days: [Int]) -> String {
        let short = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().map { short[$0 - 1] }.joined(separator: ", ")
    }

    private func logDisplay(_ log: DoseLog) -> String {
        switch log.source {
        case .reset:
            return "Container reset"
        case .correction:
            return "Adjusted \(log.doseCount > 0 ? "+" : "")\(log.doseCount)"
        case .missed:
            let count = -log.doseCount
            let unit = unitLabel(for: count)
            return "Missed \(count) \(unit)"
        case .manual, .scheduled:
            let unit = unitLabel(for: log.doseCount)
            return "\(log.doseCount) \(unit)"
        }
    }

    private func logDose() {
        let count = med.schedulesArray.first?.doseCount ?? 1
        let log = DoseLog(timestamp: .now, doseCount: count, source: .manual, medication: med)
        context.insert(log)
        context.dlSave()
        Haptic.success()
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func logExtraDose() {
        let count = med.schedulesArray.first?.doseCount ?? 1
        let log = DoseLog(timestamp: .now, doseCount: count, source: .manual, medication: med)
        context.insert(log)
        context.dlSave()
        Haptic.success()
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func logMissed() {
        let inserted = DoseLogActions.logMissed(for: med, in: context)
        if inserted { Haptic.tap(.soft) }
    }

    private func togglePause() {
        if med.isPaused {
            resumeMedication()
        } else {
            med.pause(at: .now)
            context.dlSave()
            Haptic.tap(.medium)
            let medID = med.id
            Task {
                await NotificationScheduler.shared.cancelAll(forMedicationID: medID)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func resumeMedication() {
        med.resume(at: .now)
        context.dlSave()
        Haptic.success()
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startNewContainer() {
        let remainingNow = DoseMath.dosesRemaining(med: med, at: .now)
        let refund = -(med.totalDoses - remainingNow)
        // Refund the unused portion so the count returns to `totalDoses` while
        // preserving historical math. We deliberately do NOT mutate
        // `med.startDate` — the schedule-based usage curve must continue past
        // this point. The "Started" field reads the latest .reset log instead.
        let resetLog = DoseLog(timestamp: .now, doseCount: refund, source: .reset, medication: med)
        context.insert(resetLog)
        context.dlSave()
        Haptic.success()
        Task { await NotificationScheduler.shared.rescheduleAll(meds: [med]) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// "Started" shown in the container section — the latest .reset timestamp
    /// if a refill has happened, otherwise the original startDate.
    private var startedDisplay: Date {
        let resets = med.logsArray.filter { $0.source == .reset }.map(\.timestamp)
        return resets.max() ?? med.startDate
    }
}

#if DEBUG
import SwiftData

private struct MedicationDetailPreviewHost: View {
    let med: Medication
    let container: ModelContainer
    init(_ build: () -> Medication) {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        let ctx = ModelContext(c)
        let m = build()
        ctx.insert(m)
        m.schedules?.forEach { ctx.insert($0) }
        m.logs?.forEach { ctx.insert($0) }
        try? ctx.save()
        self.med = m
        self.container = c
    }
    var body: some View {
        NavigationStack { MedicationDetailView(med: med) }
            .modelContainer(container)
    }
}

#Preview("Scheduled") {
    MedicationDetailPreviewHost { PreviewFixtures.withLogs(PreviewFixtures.scheduledMed()) }
}

#Preview("Running low") {
    MedicationDetailPreviewHost { PreviewFixtures.lowMed() }
}

#Preview("As-needed") {
    MedicationDetailPreviewHost { PreviewFixtures.asNeededMed() }
}
#endif
