import SwiftUI
import SwiftData
import WidgetKit
import DoseCore

struct HistoryView: View {
    let med: Medication
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var editingLog: DoseLog?
    @State private var isSelecting: Bool = false
    @State private var selection: Set<UUID> = []
    @State private var confirmBulkDelete: Bool = false

    private var accent: Color { DLAccent.from(hex: med.colorHex).color }

    private var allLogIDs: Set<UUID> {
        Set(sections.flatMap { $0.entries }.map { $0.log.id })
    }

    private struct Section: Identifiable {
        let id = UUID()
        let label: String
        let entries: [Entry]
    }

    private struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let display: String
        let source: LogSource
        let log: DoseLog
    }

    private var sections: [Section] {
        let cal = Calendar.current
        let now = Date.now
        let todayStart = cal.startOfDay(for: now)
        let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart)!
        let weekStart = cal.date(byAdding: .day, value: -7, to: todayStart)!

        let presentation = MedicationLogPresentation.resolve(for: med, now: now, calendar: cal, includeSynthetic: true)
        let combined = presentation.synthetic + presentation.realLogs
        let sorted = combined.sorted { $0.timestamp > $1.timestamp }

        var today: [Entry] = []
        var yesterday: [Entry] = []
        var thisWeek: [Entry] = []
        var earlier: [Entry] = []

        for log in sorted {
            let entry = Entry(timestamp: log.timestamp, display: display(for: log), source: log.source, log: log)
            switch log.timestamp {
            case _ where log.timestamp >= todayStart:     today.append(entry)
            case _ where log.timestamp >= yesterdayStart: yesterday.append(entry)
            case _ where log.timestamp >= weekStart:      thisWeek.append(entry)
            default:                                      earlier.append(entry)
            }
        }

        var out: [Section] = []
        if !today.isEmpty     { out.append(.init(label: "Today",     entries: today)) }
        if !yesterday.isEmpty { out.append(.init(label: "Yesterday", entries: yesterday)) }
        if !thisWeek.isEmpty  { out.append(.init(label: "This week", entries: thisWeek)) }
        if !earlier.isEmpty   { out.append(.init(label: "Earlier",   entries: earlier)) }
        return out
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("All logged doses for this medication.")
                        .font(DL.Text.subhead15)
                        .foregroundStyle(DL.text2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)

                    ForEach(sections) { section in
                        HStack {
                            Text(section.label.uppercased())
                                .font(.system(size: 13, weight: .medium))
                                .tracking(0.4)
                                .foregroundStyle(DL.text2)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20).padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(section.entries.enumerated()), id: \.element.id) { idx, entry in
                                rowView(for: entry)
                                if idx < section.entries.count - 1 { Divider().padding(.leading, 16) }
                            }
                        }
                        .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)
                    }
                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle(med.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { exitSelectMode() }
                            .foregroundStyle(DL.text2)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(allLogIDs.isEmpty || selection != allLogIDs ? "Select all" : "Deselect all") {
                            if selection == allLogIDs {
                                selection.removeAll()
                            } else {
                                selection = allLogIDs
                            }
                            Haptic.tap(.light)
                        }
                        .foregroundStyle(accent)
                        .disabled(allLogIDs.isEmpty)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            confirmBulkDelete = true
                        } label: {
                            Text(selection.isEmpty ? "Delete" : "Delete (\(selection.count))")
                                .fontWeight(.semibold)
                                .foregroundStyle(selection.isEmpty ? DL.text3 : .red)
                        }
                        .disabled(selection.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Select") {
                            isSelecting = true
                            selection.removeAll()
                        }
                        .foregroundStyle(accent)
                        .disabled(sections.isEmpty)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }.foregroundStyle(accent)
                    }
                }
            }
            .sheet(item: $editingLog) { log in
                EditLogDateSheet(log: log, accent: accent) { newDate in
                    DoseLogActions.updateTimestamp(log, to: newDate, for: med, in: context)
                }
            }
            .confirmationDialog(
                "Delete \(selection.count) \(selection.count == 1 ? "entry" : "entries")?",
                isPresented: $confirmBulkDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { performBulkDelete() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    @ViewBuilder
    private func rowView(for entry: Entry) -> some View {
        let isSelected = selection.contains(entry.log.id)
        Button {
            guard isSelecting else { return }
            if isSelected {
                selection.remove(entry.log.id)
            } else {
                selection.insert(entry.log.id)
            }
            Haptic.tap(.light)
        } label: {
            ActivityRow(
                timestamp: entry.timestamp,
                displayText: entry.display,
                source: entry.source,
                accent: accent,
                isSelectMode: isSelecting,
                isSelected: isSelected
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(ConditionalContextMenu(enabled: !isSelecting) {
            if entry.log.source == .reset {
                Button { editingLog = entry.log } label: {
                    Label("Edit date", systemImage: "calendar")
                }
            }
            Button(role: .destructive) { erase(entry.log) } label: {
                Label("Erase", systemImage: "trash")
            }
        })
    }

    private func exitSelectMode() {
        isSelecting = false
        selection.removeAll()
    }

    private func performBulkDelete() {
        let logs = sections.flatMap { $0.entries }
            .filter { selection.contains($0.log.id) }
            .map { $0.log }
        DoseLogActions.eraseMany(logs, for: med, in: context)
        exitSelectMode()
    }

    private func erase(_ log: DoseLog) {
        DoseLogActions.erase(log, for: med, in: context)
    }

    private func display(for log: DoseLog) -> String {
        let base = med.form.defaultUnitLabel
        switch log.source {
        case .reset: return "Container reset"
        case .correction: return "Adjusted \(log.doseCount > 0 ? "+" : "")\(log.doseCount)"
        case .missed:
            let count = -log.doseCount
            let unit = count == 1 ? base : base + "s"
            return "Missed \(count) \(unit)"
        case .manual, .scheduled:
            let unit = log.doseCount == 1 ? base : base + "s"
            return "\(log.doseCount) \(unit)"
        }
    }
}

/// Applies a `.contextMenu` only when `enabled` — used to suppress the
/// long-press menu while the history is in multi-select mode.
private struct ConditionalContextMenu<MenuItems: View>: ViewModifier {
    let enabled: Bool
    @ViewBuilder let menuItems: () -> MenuItems

    func body(content: Content) -> some View {
        if enabled {
            content.contextMenu(menuItems: menuItems)
        } else {
            content
        }
    }
}

#if DEBUG
private struct HistoryPreviewHost: View {
    let med: Medication
    let container: ModelContainer
    init() {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        let ctx = ModelContext(c)
        let m = PreviewFixtures.withLogs(PreviewFixtures.scheduledMed())
        ctx.insert(m)
        m.schedules?.forEach { ctx.insert($0) }
        m.logs?.forEach { ctx.insert($0) }
        try? ctx.save()
        self.med = m
        self.container = c
    }
    var body: some View {
        NavigationStack { HistoryView(med: med) }
            .modelContainer(container)
    }
}

#Preview {
    HistoryPreviewHost()
}
#endif
