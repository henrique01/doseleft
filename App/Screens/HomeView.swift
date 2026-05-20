import SwiftUI
import SwiftData
import WidgetKit
import DoseCore

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Medication> { $0.isActive == true })
    private var meds: [Medication]

    @State private var showAdd = false
    @State private var showSettings = false
    @State private var detailMed: Medication?
    @State private var pendingDelete: Medication?

    var body: some View {
        NavigationStack {
            Group {
                if meds.isEmpty {
                    HomeEmptyView(onAdd: { showAdd = true })
                } else {
                    populatedList
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(DL.text)
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DLAccent.lavender.color)
                    }
                    .accessibilityLabel("Add medication")
                }
            }
            .navigationDestination(item: $detailMed) { med in
                MedicationDetailView(med: med)
            }
            .sheet(isPresented: $showAdd) {
                MedicationEditView(existing: nil)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .confirmationDialog(
                pendingDelete.map { "Delete \($0.name)?" } ?? "",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { med in
                Button("Delete medication", role: .destructive) { delete(med) }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { _ in
                Text("This removes the medication, its schedule, and all logged doses. This cannot be undone.")
            }
        }
        .tint(DLAccent.lavender.color)
    }

    private func delete(_ med: Medication) {
        let id = med.id
        context.delete(med)
        context.dlSave()
        Haptic.success()
        pendingDelete = nil
        Task { await NotificationScheduler.shared.cancelAll(forMedicationID: id) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var sortedMeds: [Medication] {
        let now = Date.now
        return meds.sorted { lhs, rhs in
            percentRemaining(lhs, at: now) < percentRemaining(rhs, at: now)
        }
    }

    private func percentRemaining(_ med: Medication, at now: Date) -> Double {
        guard med.totalDoses > 0 else { return 0 }
        return Double(DoseMath.dosesRemaining(med: med, at: now)) / Double(med.totalDoses)
    }

    private var populatedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedMeds.enumerated()), id: \.element.id) { idx, med in
                    Button {
                        Haptic.tap(.soft)
                        detailMed = med
                    } label: {
                        MedRow(
                            med: med,
                            daysLeft: DoseMath.daysRemaining(med: med, at: .now),
                            dosesRemaining: DoseMath.dosesRemaining(med: med, at: .now),
                            nextDose: nextDoseTuple(med: med),
                            isLow: DoseMath.isRunningLow(med: med, at: .now)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            pendingDelete = med
                        } label: {
                            Label("Delete medication", systemImage: "trash")
                        }
                    }
                    .accessibilityAction(named: "Delete medication") {
                        pendingDelete = med
                    }
                    if idx < sortedMeds.count - 1 {
                        Divider().padding(.leading, 78)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func nextDoseTuple(med: Medication) -> (date: Date, count: Int)? {
        guard let n = DoseMath.nextDose(med: med, after: .now) else { return nil }
        return (n.date, n.schedule.doseCount)
    }
}

#if DEBUG
#Preview("Populated") {
    HomeView()
        .modelContainer(PreviewFixtures.container())
}

#Preview("Empty") {
    HomeView()
        .modelContainer(PreviewFixtures.emptyContainer())
}
#endif
