import SwiftUI
import SwiftData
import DoseCore

struct WatchHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Medication> { $0.isActive == true })
    private var meds: [Medication]

    var body: some View {
        NavigationStack {
            Group {
                if meds.isEmpty {
                    emptyState
                } else {
                    medList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let m = meds.first(where: { $0.id == id }) {
                    WatchLogView(med: m)
                }
            }
        }
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills.fill")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("No medications")
                .font(.system(size: 14, weight: .semibold))
            Text("Add one on your iPhone — they'll sync over iCloud.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
            #if DEBUG
            // Long-press the empty illustration in debug builds to seed sample
            // data so the watch UI can be tested without CloudKit sync.
            Button("Seed sample data") {
                seedSampleData()
            }
            .font(.system(size: 11))
            .padding(.top, 6)
            #endif
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
    }

    private var medList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(sorted) { med in
                    NavigationLink(value: med.id) {
                        row(for: med)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }

    private var sorted: [Medication] {
        // Sort by % remaining (doses ÷ totalDoses) so PRN and scheduled meds
        // can be compared on the same axis — closest to empty floats to the top.
        let now = Date.now
        return meds.sorted { percentRemaining($0, at: now) < percentRemaining($1, at: now) }
    }

    private func percentRemaining(_ med: Medication, at now: Date) -> Double {
        guard med.totalDoses > 0 else { return 0 }
        return Double(DoseMath.dosesRemaining(med: med, at: now)) / Double(med.totalDoses)
    }

    private func row(for med: Medication) -> some View {
        let accent = DLAccent.from(hex: med.colorHex).color
        let remaining = DoseMath.dosesRemaining(med: med, at: .now)
        let fill = med.totalDoses > 0 ? Double(remaining) / Double(med.totalDoses) : 0
        let days = DoseMath.daysRemaining(med: med, at: .now)
        let unit = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        let unitText = remaining == 1 ? unit : unit + "s"
        return HStack(spacing: 8) {
            DLRing(progress: fill, size: 32, stroke: 5.4, color: accent, trackColor: .white.opacity(0.12))
            VStack(alignment: .leading, spacing: 1) {
                Text(med.name).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                if med.isAsNeeded {
                    Text("\(remaining) \(unitText) left")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(days) days · \(remaining) \(unitText)")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    #if DEBUG
    private func seedSampleData() {
        let flixotide = Medication(
            name: "Flixotide",
            iconSymbol: MedicationIcon.inhaler.symbolName,
            colorHex: DLAccent.slate.hex,
            totalDoses: 120,
            startDate: .now,
            trackingMode: .automatic
        )
        flixotide.schedules = [
            DoseSchedule(timeHour: 8, doseCount: 2, weekdays: Array(1...7), medication: flixotide),
            DoseSchedule(timeHour: 20, doseCount: 2, weekdays: Array(1...7), medication: flixotide),
        ]
        let vitd = Medication(
            name: "Vitamin D",
            iconSymbol: MedicationIcon.drops.symbolName,
            colorHex: DLAccent.ochre.hex,
            totalDoses: 30,
            startDate: .now,
            trackingMode: .manual
        )
        vitd.schedules = [
            DoseSchedule(timeHour: 9, doseCount: 1, weekdays: Array(1...7), medication: vitd)
        ]
        context.insert(flixotide)
        context.insert(vitd)
        context.dlSave()
    }
    #endif
}

#if DEBUG
#Preview("Populated") {
    WatchHomeView()
        .modelContainer(PreviewFixtures.container())
}

#Preview("Empty") {
    WatchHomeView()
        .modelContainer(PreviewFixtures.emptyContainer())
}
#endif
