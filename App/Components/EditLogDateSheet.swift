import SwiftUI
import DoseCore

/// Small sheet that lets the user reassign a `DoseLog`'s timestamp. Used today
/// for correcting the date of a container reset; can be extended to other log
/// kinds when needed.
struct EditLogDateSheet: View {
    let log: DoseLog
    let accent: Color
    let onSave: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(log: DoseLog, accent: Color, onSave: @escaping (Date) -> Void) {
        self.log = log
        self.accent = accent
        self.onSave = onSave
        _date = State(initialValue: log.timestamp)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(DL.text2)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                DatePicker(
                    "Date",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(accent)
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Edit date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(DL.text2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(date)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(accent)
                }
            }
        }
        .tint(accent)
        .presentationDetents([.medium, .large])
    }

    private var title: String {
        switch log.source {
        case .reset: return "Container reset date"
        case .correction: return "Adjustment date"
        case .missed: return "Missed dose date"
        case .manual, .scheduled: return "Dose date"
        }
    }
}
