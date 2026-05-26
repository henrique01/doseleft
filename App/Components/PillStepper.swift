import SwiftUI
import DoseCore

/// Matches the design's −/+ pill stepper. The number is a static `Text` by
/// default; pass `editable: true` to make it tappable as a number-pad input
/// (the keyboard's Done button is provided by the parent form's toolbar).
struct PillStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...999
    var size: PillStepperSize = .large
    var editable: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: size.gap) {
            stepButton(symbol: "minus") {
                value = max(range.lowerBound, value - 1)
            }
            numberView
            stepButton(symbol: "plus") {
                value = min(range.upperBound, value + 1)
            }
        }
    }

    @ViewBuilder
    private var numberView: some View {
        if editable {
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(size.font)
                .foregroundStyle(DL.text)
                // Explicit frame so the TextField never expands and pushes the
                // + button off the trailing edge. Wide enough for 4 digits.
                .frame(width: size.editableNumberWidth)
                .focused($isFocused)
                .onChange(of: value) { _, newValue in
                    // Clamp on commit so users can't enter out-of-range values.
                    let clamped = min(range.upperBound, max(range.lowerBound, newValue))
                    if clamped != newValue { value = clamped }
                }
                .accessibilityLabel("Doses")
                .accessibilityValue("\(value)")
        } else {
            Text("\(value)")
                .font(size.font)
                .foregroundStyle(DL.text)
                .frame(minWidth: size.numberWidth)
        }
    }

    private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptic.tap(.light); action() }) {
            Image(systemName: symbol)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(DL.text)
                .frame(width: size.buttonSize, height: size.buttonSize)
                .background(DL.fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

enum PillStepperSize {
    case small, large

    var buttonSize: CGFloat { self == .small ? 28 : 32 }
    var iconSize:   CGFloat { self == .small ? 14 : 16 }
    var numberWidth: CGFloat { self == .small ? 32 : 48 }
    /// Wider fixed width for the editable TextField variant so 4-digit values
    /// fit without clipping and the trailing + button stays visible.
    var editableNumberWidth: CGFloat { self == .small ? 60 : 90 }
    var gap: CGFloat { self == .small ? 12 : 14 }
    var font: Font {
        self == .small ? DL.Numerals.stepper22 : DL.Numerals.title28
    }
}

#if DEBUG
private struct PillStepperPreview: View {
    @State private var value: Int
    let range: ClosedRange<Int>
    let size: PillStepperSize
    let editable: Bool

    init(_ initial: Int, range: ClosedRange<Int> = 1...999, size: PillStepperSize = .large, editable: Bool = false) {
        _value = State(initialValue: initial)
        self.range = range
        self.size = size
        self.editable = editable
    }

    var body: some View {
        PillStepper(value: $value, range: range, size: size, editable: editable)
    }
}

#Preview("Large") {
    PillStepperPreview(5)
        .padding()
}

#Preview("Small") {
    PillStepperPreview(3, size: .small)
        .padding()
}

#Preview("Editable") {
    PillStepperPreview(42, editable: true)
        .padding()
}
#endif
