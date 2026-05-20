import SwiftUI
import DoseCore

/// Click-pen calculator. Mirrors the math of the glapp.io "Mounjaro clicks"
/// tool: given pen volume, concentration, prescribed dose and the pen's
/// units-per-mL scale, derive clicks-per-dose and doses-per-pen. On Apply
/// the parent form receives `totalDoses`, `clicksPerDose`, and `doseMg`
/// so the rest of DoseLeft (schedules, notifications, math) treats the pen
/// like any other medication counted in integer doses.
struct PenCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accent: Color
    /// Bound outputs — written on Apply.
    @Binding var totalDoses: Int
    @Binding var clicksPerDose: Int
    @Binding var doseMg: Double

    // Decimal inputs are stored as integer "tenths" so the number-pad keyboard
    // is all we ever need: the user types "25" and the formatter inserts the
    // locale's decimal separator to show "2,5" (or "2.5" in en). Each step
    // button adjusts by 5 tenths (= 0.5). Ranges keep results sensible.
    @State private var penVolumeTenths: Int            // 1...999  (0.1–99.9 mL)
    @State private var concentrationTenths: Int        // 1...9999 (0.1–999.9 mg/mL)
    @State private var doseTenths: Int                 // 1...999  (0.1–99.9 mg)
    @State private var unitsPerML: Int

    @FocusState private var focused: Field?
    private enum Field: Hashable { case volume, concentration, dose }

    private static let volumeRange = 1...999
    private static let concentrationRange = 1...9999
    private static let doseRange = 1...999

    init(
        accent: Color,
        totalDoses: Binding<Int>,
        clicksPerDose: Binding<Int>,
        doseMg: Binding<Double>
    ) {
        self.accent = accent
        self._totalDoses = totalDoses
        self._clicksPerDose = clicksPerDose
        self._doseMg = doseMg
        // Seed inputs from the parent form when re-opening the sheet.
        let initialClicks = max(0, clicksPerDose.wrappedValue)
        let initialDose = doseMg.wrappedValue
        // Sensible defaults: 3 mL pen at 100 units/mL is the KwikPen norm.
        self._penVolumeTenths = State(initialValue: 30)            // 3.0 mL
        let seededConcentration: Int = {
            guard initialDose > 0, initialClicks > 0 else { return 100 } // 10.0
            let mgPerML = (initialDose / Double(initialClicks)) * 100.0
            return max(1, Int((mgPerML * 10).rounded()))
        }()
        self._concentrationTenths = State(initialValue: seededConcentration)
        self._doseTenths = State(
            initialValue: initialDose > 0 ? max(1, Int((initialDose * 10).rounded())) : 50
        )
        self._unitsPerML = State(initialValue: 100)
    }

    // MARK: - Derived

    private var penVolumeML: Double { Double(penVolumeTenths) / 10.0 }
    private var concentrationMgPerML: Double { Double(concentrationTenths) / 10.0 }
    private var doseMgInput: Double { Double(doseTenths) / 10.0 }

    private var totalClicks: Int {
        Int((penVolumeML * Double(unitsPerML)).rounded())
    }
    private var derivedClicksPerDose: Int {
        guard concentrationMgPerML > 0, doseMgInput > 0 else { return 0 }
        let clicks = (doseMgInput / concentrationMgPerML) * Double(unitsPerML)
        return Int(clicks.rounded())
    }
    private var dosesPerPen: Int {
        guard derivedClicksPerDose > 0 else { return 0 }
        return totalClicks / derivedClicksPerDose
    }
    private var mgPerClick: Double {
        guard unitsPerML > 0 else { return 0 }
        return concentrationMgPerML / Double(unitsPerML)
    }
    private var canApply: Bool {
        derivedClicksPerDose > 0 && dosesPerPen > 0 && doseMgInput > 0 && concentrationMgPerML > 0
    }

    private var decimalSeparator: String { Locale.current.decimalSeparator ?? "." }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    helpText
                    inputsSection
                    outputsSection
                    Spacer(minLength: 32)
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle("Pen calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(DL.text2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply", action: apply)
                        .fontWeight(.semibold)
                        .foregroundStyle(canApply ? accent : DL.text3)
                        .disabled(!canApply)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focused = nil
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(accent)
                }
            }
        }
        .tint(accent)
    }

    // MARK: - Sections

    private var helpText: some View {
        Text("Enter your pen's volume, concentration, and the dose your prescriber set. We'll calculate the clicks to dial each time.")
            .font(DL.Text.footnote13)
            .foregroundStyle(DL.text2)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var inputsSection: some View {
        // Grid keeps the label / − / value / + / unit columns aligned across
        // every row, including the integer "Units per mL" row. Without it
        // each HStack picks its own spacing and the +/− buttons land at
        // different x positions per row.
        section("Pen") {
            Grid(alignment: .center, horizontalSpacing: 10, verticalSpacing: 0) {
                tenthsGridRow(title: "Pen volume", unit: "mL",
                              tenths: $penVolumeTenths, range: Self.volumeRange, field: .volume)
                gridDivider
                tenthsGridRow(title: "Concentration", unit: "mg/mL",
                              tenths: $concentrationTenths, range: Self.concentrationRange, field: .concentration)
                gridDivider
                tenthsGridRow(title: "Dose", unit: "mg",
                              tenths: $doseTenths, range: Self.doseRange, field: .dose)
                gridDivider
                intGridRow(title: "Units per mL", value: $unitsPerML, range: 10...500)
            }
            .padding(.horizontal, 16)
        }
    }

    /// Five-column divider spanning the whole row (label, −, value, +, unit).
    @ViewBuilder
    private var gridDivider: some View {
        GridRow {
            Divider()
                .gridCellColumns(5)
                .gridCellUnsizedAxes(.horizontal)
        }
    }

    private var outputsSection: some View {
        section("Result") {
            VStack(spacing: 0) {
                resultRow("Clicks per dose", value: derivedClicksPerDose > 0 ? "\(derivedClicksPerDose)" : "—", emphasised: true)
                Divider().padding(.leading, 16)
                resultRow("Doses per pen", value: dosesPerPen > 0 ? "\(dosesPerPen)" : "—")
                Divider().padding(.leading, 16)
                resultRow("Per click", value: mgPerClick > 0 ? formatMg(mgPerClick) + " mg" : "—")
                Divider().padding(.leading, 16)
                resultRow("Total clicks in pen", value: "\(totalClicks)")
            }
        }
    }

    // MARK: - Row builders

    /// Fixed widths for the three trailing columns. The label column takes
    /// whatever's left; the value column is wide enough for a 4-digit
    /// formatted number ("999,9"); the unit column fits "mg/mL".
    private static let valueColumnWidth: CGFloat = 78
    private static let unitColumnWidth: CGFloat = 54

    @ViewBuilder
    private func tenthsGridRow(
        title: String,
        unit: String,
        tenths: Binding<Int>,
        range: ClosedRange<Int>,
        field: Field
    ) -> some View {
        GridRow {
            Text(title)
                .font(DL.Text.body17)
                .foregroundStyle(DL.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
            stepButton(symbol: "minus") {
                tenths.wrappedValue = max(range.lowerBound, tenths.wrappedValue - 5)
            }
            TextField("", text: tenthsTextBinding(for: tenths, range: range))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(DL.Numerals.row17)
                .foregroundStyle(DL.text)
                .frame(width: Self.valueColumnWidth)
                .focused($focused, equals: field)
            stepButton(symbol: "plus") {
                tenths.wrappedValue = min(range.upperBound, tenths.wrappedValue + 5)
            }
            Text(unit)
                .font(DL.Text.subhead15)
                .foregroundStyle(DL.text2)
                .frame(width: Self.unitColumnWidth, alignment: .leading)
        }
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        .onTapGesture { focused = field }
    }

    @ViewBuilder
    private func intGridRow(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        GridRow {
            Text(title)
                .font(DL.Text.body17)
                .foregroundStyle(DL.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
            stepButton(symbol: "minus") {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
            }
            Text("\(value.wrappedValue)")
                .font(DL.Numerals.row17)
                .foregroundStyle(DL.text)
                .frame(width: Self.valueColumnWidth)
            stepButton(symbol: "plus") {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
            }
            // Empty unit cell so the column structure matches the decimal rows.
            Color.clear
                .frame(width: Self.unitColumnWidth, height: 1)
        }
        .frame(minHeight: 54)
    }

    @ViewBuilder
    private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.tap(.light)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DL.text2)
                .frame(width: 32, height: 32)
                .background(DL.fill, in: Circle())
        }
        .buttonStyle(.plain)
    }

    /// Two-way binding: the user types digits, the display shows them
    /// formatted with the locale's decimal separator one place from the
    /// right ("25" → "2,5", "5" → "0,5", "150" → "15,0"). Non-digit input
    /// is stripped silently so the number pad stays the only thing needed.
    private func tenthsTextBinding(for binding: Binding<Int>, range: ClosedRange<Int>) -> Binding<String> {
        Binding(
            get: { formatTenths(binding.wrappedValue) },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                // Trim leading zeros and cap the digit count to the range's
                // upper bound width so the field can't blow past 99,9 etc.
                let maxDigits = String(range.upperBound).count
                let capped = String(digits.prefix(maxDigits))
                let parsed = Int(capped) ?? 0
                binding.wrappedValue = min(range.upperBound, max(0, parsed))
            }
        )
    }

    private func formatTenths(_ tenths: Int) -> String {
        let value = max(0, tenths)
        let intPart = value / 10
        let fracPart = value % 10
        return "\(intPart)\(decimalSeparator)\(fracPart)"
    }

    @ViewBuilder
    private func resultRow(_ label: String, value: String, emphasised: Bool = false) -> some View {
        HStack {
            Text(label).font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            Text(value)
                .font(emphasised ? DL.Numerals.display(20) : DL.Numerals.row17)
                .foregroundStyle(emphasised ? accent : DL.text2)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(DL.text2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20).padding(.bottom, 8)

            VStack(spacing: 0, content: content)
                .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Actions

    private func apply() {
        guard canApply else { return }
        totalDoses = dosesPerPen
        clicksPerDose = derivedClicksPerDose
        doseMg = doseMgInput
        Haptic.success()
        dismiss()
    }

    private func formatMg(_ value: Double) -> String {
        // Per-click amounts are typically 0.05–0.50 mg — three decimals
        // reads cleanly without trailing noise for whole numbers.
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 3
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.3f", value)
    }
}
