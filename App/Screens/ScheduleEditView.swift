import SwiftUI
import DoseCore

struct ScheduleEditView: View {
    @Binding var schedule: ScheduleDraft
    let accent: Color
    /// `nil` when the schedule cannot be removed (last remaining dose time).
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Spacer().frame(height: 8)
                    sectionHeader("Dose time")
                    groupedCard {
                        timeRow
                        Divider().padding(.leading, 16)
                        doseRow
                        Divider().padding(.leading, 16)
                        weekdayRow
                    }
                    if onDelete != nil {
                        deleteButton.padding(.top, 12)
                    }
                    Spacer(minLength: 24)
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(accent)
                }
            }
            .confirmationDialog(
                "Remove this dose time?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Remove dose time", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Future doses scheduled at this time will no longer count.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var deleteButton: some View {
        Button {
            Haptic.tap(.medium)
            confirmDelete = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Remove dose time").font(DL.Text.body17)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var timeRow: some View {
        HStack {
            Text("Time").font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
    }

    private var doseRow: some View {
        HStack {
            Text("Doses").font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            PillStepper(value: $schedule.count, range: 1...99, size: .small)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    private var weekdayRow: some View {
        HStack {
            Text("Days").font(DL.Text.subhead15).foregroundStyle(DL.text2)
            Spacer()
            WeekdayPicker(selected: $schedule.weekdays, accent: accent)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = schedule.hour; c.minute = schedule.minute
                return Calendar.current.date(from: c) ?? .now
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                schedule.hour = comps.hour ?? 8
                schedule.minute = comps.minute ?? 0
            }
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(DL.text2)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func groupedCard<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0, content: content)
            .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
    }
}

#if DEBUG
private struct ScheduleEditPreviewHost: View {
    @State var draft = ScheduleDraft.defaultEvening()
    let allowDelete: Bool
    var body: some View {
        ScheduleEditView(
            schedule: $draft,
            accent: DLAccent.lavender.color,
            onDelete: allowDelete ? {} : nil
        )
    }
}

#Preview("Single (no delete)") {
    ScheduleEditPreviewHost(allowDelete: false)
}

#Preview("Removable") {
    ScheduleEditPreviewHost(allowDelete: true)
}
#endif
