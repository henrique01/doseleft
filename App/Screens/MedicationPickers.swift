import SwiftUI
import DoseCore

// Bottom-sheet pickers used by `MedicationEditView` for choosing a medication
// form (Tablet, Inhaler, …) and overriding the SF Symbol shown on the badge.

struct FormPickerSheet: View {
    @Binding var selection: MedicationForm
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(MedicationForm.allCases) { f in
                        Button {
                            Haptic.tap(.light)
                            selection = f
                            dismiss()
                        } label: {
                            row(for: f)
                        }
                        .buttonStyle(.plain)
                        if f != MedicationForm.allCases.last {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(DL.surface)
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Form")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .tint(accent)
    }

    @ViewBuilder
    private func row(for f: MedicationForm) -> some View {
        let isSelected = (f == selection)
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isSelected ? accent : DL.fill)
                    .frame(width: 36, height: 36)
                Image(systemName: f.defaultIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : DL.text2)
            }
            Text(f.displayName)
                .font(DL.Text.body17)
                .foregroundStyle(DL.text)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

struct IconPickerSheet: View {
    @Binding var selection: String
    let form: MedicationForm
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                VStack(spacing: 2) {
                    Text("Choose icon")
                        .font(DL.Text.headline17)
                        .foregroundStyle(DL.text)
                    Text("Suggested for \(form.displayName.lowercased())")
                        .font(DL.Text.footnote13)
                        .foregroundStyle(DL.text2)
                }
                .padding(.top, 4)
                .padding(.bottom, 12)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(form.suggestedIcons, id: \.self) { symbol in
                            cell(for: symbol)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .tint(accent)
    }

    @ViewBuilder
    private func cell(for symbol: String) -> some View {
        let isSelected = (symbol == selection)
        let isDefault = (symbol == form.defaultIcon)
        Button {
            Haptic.tap(.light)
            selection = symbol
            dismiss()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accent : DL.surface)
                        .frame(width: 56, height: 56)
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isSelected ? .white : DL.text2)
                }
                Text(isDefault ? "Default" : " ")
                    .font(DL.Text.caption12)
                    .foregroundStyle(isSelected ? accent : DL.text2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
    }
}

#if DEBUG
#Preview("Form picker") {
    StatefulPreview(MedicationForm.tablet) { binding in
        FormPickerSheet(selection: binding, accent: DLAccent.sage.color)
    }
}

#Preview("Icon picker — tablet") {
    StatefulPreview("pills.fill") { binding in
        IconPickerSheet(selection: binding, form: .tablet, accent: DLAccent.sage.color)
    }
}

private struct StatefulPreview<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
#endif
