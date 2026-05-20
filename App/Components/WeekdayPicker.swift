import SwiftUI
import DoseCore

/// Seven small day-of-week circles (S M T W T F S). Filled = selected.
struct WeekdayPicker: View {
    @Binding var selected: Set<Int>           // 1=Sun … 7=Sat
    let accent: Color

    private let letters = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...7, id: \.self) { day in
                Button {
                    Haptic.tap(.light)
                    if selected.contains(day) {
                        if selected.count > 1 { selected.remove(day) }
                    } else {
                        selected.insert(day)
                    }
                } label: {
                    Text(letters[day - 1])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selected.contains(day) ? .white : DL.text2)
                        .frame(width: 28, height: 28)
                        .background(selected.contains(day) ? accent : DL.fill, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fullName(for: day))
                .accessibilityValue(selected.contains(day) ? "selected" : "not selected")
            }
        }
    }

    private func fullName(for day: Int) -> String {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day - 1]
    }
}
