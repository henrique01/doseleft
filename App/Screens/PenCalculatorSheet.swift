import SwiftUI
import DoseCore

/// Calculator for refillable click-dial pens used with compounded GLP-1
/// medications (tirzepatide, semaglutide, etc.). NOT for branded Mounjaro
/// single-dose pens — those have no dial. Given vial volume, concentration,
/// prescribed dose and the pen's units-per-mL scale, derives clicks-per-dose
/// and doses-per-pen. On Apply the parent form receives `totalDoses`,
/// `clicksPerDose`, and `doseMg` so the rest of DoseLeft (schedules,
/// notifications, math) treats the pen like any other medication counted
/// in integer doses.
struct PenCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accent: Color
    /// Bound outputs — written on Apply.
    @Binding var totalDoses: Int
    @Binding var clicksPerDose: Int
    @Binding var doseMg: Double

    // Decimal inputs are stored as integer "hundredths" so the number-pad
    // keyboard is all we ever need: the user types "500" and the formatter
    // shifts each digit one place left, locale-formatted to "5,00" (or "5.00"
    // in en). Each step button adjusts by 50 hundredths (= 0.5). Ranges keep
    // results sensible.
    @State private var penVolumeHundredths: Int       // 1...9999  (0.01–99.99 mL)
    @State private var concentrationHundredths: Int   // 1...99999 (0.01–999.99 mg/mL)
    @State private var totalMgHundredths: Int         // 1...999999 (0.01–9999.99 mg per vial)
    @State private var doseHundredths: Int            // 1...9999  (0.01–99.99 mg)
    @State private var unitsPerML: Int
    @State private var entryMode: ConcentrationEntryMode = .concentration
    @State private var showAdvanced: Bool = false

    // Mirror @State Strings for each number-pad field. SwiftUI's TextField
    // ignores a transformed Binding<String> while the field is first
    // responder (so reformatted text only appears on resign). Driving the
    // field with a real @State and reformatting inside .onChange forces the
    // visible text to refresh on every keystroke.
    @State private var penVolumeText: String = ""
    @State private var concentrationText: String = ""
    @State private var totalMgText: String = ""
    @State private var doseText: String = ""

    @FocusState private var focused: Field?
    fileprivate enum Field: Hashable { case volume, concentration, totalMg, dose }
    private enum ConcentrationEntryMode: Hashable { case concentration, totalMg }

    private static let volumeRange = 1...9999
    private static let concentrationRange = 1...99999
    private static let totalMgRange = 1...999999
    private static let doseRange = 1...9999

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
        let seedVolume = 300                            // 3.00 mL
        let seedConcentration: Int = {
            guard initialDose > 0, initialClicks > 0 else { return 1000 } // 10.00
            let mgPerML = (initialDose / Double(initialClicks)) * 100.0
            return max(1, Int((mgPerML * 100).rounded()))
        }()
        // Total mg in vial seeded from concentration × 3 mL default — keeps the
        // pair consistent when the user opens the sheet and flips to Total mg.
        let seedTotal = max(1, Int((Double(seedConcentration) / 100.0 * 3.0 * 100).rounded()))
        let seedDose = initialDose > 0
            ? max(1, Int((initialDose * 100).rounded()))
            : 500                                       // 5.00 mg
        self._penVolumeHundredths = State(initialValue: seedVolume)
        self._concentrationHundredths = State(initialValue: seedConcentration)
        self._totalMgHundredths = State(initialValue: min(999999, seedTotal))
        self._doseHundredths = State(initialValue: seedDose)
        self._unitsPerML = State(initialValue: 100)

        let sep = Locale.current.decimalSeparator ?? "."
        self._penVolumeText = State(initialValue: Self.formatHundredthsStatic(seedVolume, separator: sep))
        self._concentrationText = State(initialValue: Self.formatHundredthsStatic(seedConcentration, separator: sep))
        self._totalMgText = State(initialValue: Self.formatHundredthsStatic(min(999999, seedTotal), separator: sep))
        self._doseText = State(initialValue: Self.formatHundredthsStatic(seedDose, separator: sep))
    }

    // MARK: - Derived

    private var penVolumeML: Double { Double(penVolumeHundredths) / 100.0 }
    private var totalMgInVial: Double { Double(totalMgHundredths) / 100.0 }
    /// Concentration is the source of truth for all downstream math. In
    /// `.concentration` mode it's stored directly; in `.totalMg` mode it's
    /// derived from `totalMg / volume`. Whichever field is *not* the source
    /// is shown as a derived footnote next to the active input.
    private var concentrationMgPerML: Double {
        switch entryMode {
        case .concentration: return Double(concentrationHundredths) / 100.0
        case .totalMg:       return penVolumeML > 0 ? totalMgInVial / penVolumeML : 0
        }
    }
    private var doseMgInput: Double { Double(doseHundredths) / 100.0 }

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

    /// The dose actually delivered when `derivedClicksPerDose` integer clicks
    /// are dialed — usually slightly off from `doseMgInput` due to rounding.
    private var actualDeliveredMg: Double {
        guard unitsPerML > 0 else { return 0 }
        return Double(derivedClicksPerDose) * concentrationMgPerML / Double(unitsPerML)
    }
    /// Signed drift in percent (positive = over-dose, negative = under-dose).
    private var roundingDriftPercent: Double {
        guard doseMgInput > 0 else { return 0 }
        return (actualDeliveredMg - doseMgInput) / doseMgInput * 100
    }
    /// Show the safety banner when rounding shifts the actual dose by ≥1%.
    private var showsRoundingWarning: Bool {
        canApply && abs(roundingDriftPercent) >= 1.0
    }

    private var decimalSeparator: String { Locale.current.decimalSeparator ?? "." }

    /// Ordered list of focusable fields, in tab order. The middle slot swaps
    /// between concentration and totalMg with the mode picker.
    private var orderedFields: [Field] {
        [.volume, entryMode == .concentration ? .concentration : .totalMg, .dose]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    helpText
                    inputsSection
                    outputsSection
                    if showsRoundingWarning {
                        roundingWarningBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
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
                    Button {
                        if let prev = previousField(from: focused) { focused = prev }
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(previousField(from: focused) == nil)

                    Button {
                        if let next = nextField(from: focused) { focused = next }
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(nextField(from: focused) == nil)

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
        .onChange(of: entryMode) { _, newMode in
            // Seed the now-inactive field from the just-computed concentration
            // so the displayed numbers stay continuous across mode switches.
            switch newMode {
            case .totalMg:
                let mg = concentrationMgPerML * penVolumeML
                let clamped = min(Self.totalMgRange.upperBound,
                                  max(Self.totalMgRange.lowerBound, Int((mg * 100).rounded())))
                totalMgHundredths = clamped
                totalMgText = formatHundredths(clamped)
            case .concentration:
                let clamped = min(Self.concentrationRange.upperBound,
                                  max(Self.concentrationRange.lowerBound,
                                      Int((concentrationMgPerML * 100).rounded())))
                concentrationHundredths = clamped
                concentrationText = formatHundredths(clamped)
            }
        }
    }

    // MARK: - Sections

    private var helpText: some View {
        Text("For refillable click-dial pens used with compounded tirzepatide, semaglutide, or similar. Enter the vial's volume, concentration, and your prescribed dose.")
            .font(DL.Text.footnote13)
            .foregroundStyle(DL.text2)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var inputsSection: some View {
        // Grid keeps the label / − / value / + / unit columns aligned across
        // every row. The mode segmented control sits above the grid; the
        // Units-per-mL row hides behind an "Advanced" disclosure since the
        // value is almost always 100 for U-100 insulin-style pens.
        section("Pen") {
            VStack(spacing: 0) {
                entryModeToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                Grid(alignment: .center, horizontalSpacing: 10, verticalSpacing: 0) {
                    hundredthsGridRow(title: "Pen volume", unit: "mL",
                                      hundredths: $penVolumeHundredths,
                                      text: $penVolumeText,
                                      range: Self.volumeRange, field: .volume)
                    gridDivider
                    if entryMode == .concentration {
                        hundredthsGridRow(title: "Concentration", unit: "mg/mL",
                                          hundredths: $concentrationHundredths,
                                          text: $concentrationText,
                                          range: Self.concentrationRange,
                                          field: .concentration)
                    } else {
                        hundredthsGridRow(title: "Vial total", unit: "mg",
                                          hundredths: $totalMgHundredths,
                                          text: $totalMgText,
                                          range: Self.totalMgRange,
                                          field: .totalMg)
                    }
                    gridDivider
                    hundredthsGridRow(title: "Dose", unit: "mg",
                                      hundredths: $doseHundredths,
                                      text: $doseText,
                                      range: Self.doseRange, field: .dose)
                    if showAdvanced {
                        gridDivider
                        intGridRow(title: "Units per mL", value: $unitsPerML, range: 10...500)
                    }
                }
                .padding(.horizontal, 16)
                derivedFootnote
                advancedDisclosureRow
            }
        }
    }

    private var entryModeToggle: some View {
        Picker("", selection: $entryMode) {
            Text("mg/mL").tag(ConcentrationEntryMode.concentration)
            Text("Total mg").tag(ConcentrationEntryMode.totalMg)
        }
        .pickerStyle(.segmented)
    }

    /// Small derived-value line under the active concentration/total-mg row,
    /// showing whichever quantity isn't currently being edited.
    @ViewBuilder
    private var derivedFootnote: some View {
        HStack {
            Group {
                switch entryMode {
                case .concentration:
                    Text("= \(formatMg(concentrationMgPerML * penVolumeML)) mg in \(formatMg(penVolumeML)) mL vial")
                case .totalMg:
                    Text("= \(formatMg(concentrationMgPerML)) mg/mL")
                }
            }
            .font(DL.Text.footnote13)
            .foregroundStyle(DL.text2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    /// Tappable footer toggling the Units-per-mL row. When collapsed we still
    /// surface the current pen scale so the value isn't completely invisible.
    private var advancedDisclosureRow: some View {
        Button {
            Haptic.tap(.light)
            withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text(showAdvanced
                     ? "Hide advanced"
                     : "Advanced · pen scale \(unitsPerML) units/mL")
                    .font(DL.Text.footnote13)
                    .foregroundStyle(accent)
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private var roundingWarningBanner: some View {
        let drift = roundingDriftPercent
        let direction = drift >= 0 ? "above" : "below"
        let percent = String(format: "%.1f%%", abs(drift))
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(accent.dlSaturated())
            VStack(alignment: .leading, spacing: 2) {
                Text("Dose is rounded")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent.dlSaturated())
                Text("Dialing \(derivedClicksPerDose) clicks delivers \(formatMg(actualDeliveredMg)) mg, \(percent) \(direction) the prescribed \(formatMg(doseMgInput)) mg. Confirm with your prescriber.")
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.4), lineWidth: 0.5)
        )
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
    /// whatever's left; the value column is wide enough for the longest
    /// formatted hundredths value (e.g. "9999,99"); the unit column fits
    /// "mg/mL".
    private static let valueColumnWidth: CGFloat = 92
    private static let unitColumnWidth: CGFloat = 54

    @ViewBuilder
    private func hundredthsGridRow(
        title: String,
        unit: String,
        hundredths: Binding<Int>,
        text: Binding<String>,
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
                let new = max(range.lowerBound, hundredths.wrappedValue - 50)
                hundredths.wrappedValue = new
                text.wrappedValue = formatHundredths(new)
            }
            TextField("", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(DL.Numerals.row17)
                .foregroundStyle(DL.text)
                .frame(width: Self.valueColumnWidth)
                .focused($focused, equals: field)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let parsed = parseHundredths(newValue, range: range)
                    if parsed != hundredths.wrappedValue {
                        hundredths.wrappedValue = parsed
                    }
                    let reformatted = formatHundredths(parsed)
                    if reformatted != newValue {
                        text.wrappedValue = reformatted
                    }
                }
            stepButton(symbol: "plus") {
                let new = min(range.upperBound, hundredths.wrappedValue + 50)
                hundredths.wrappedValue = new
                text.wrappedValue = formatHundredths(new)
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

    /// Parse user input as right-aligned digits in a hundredths integer.
    /// Non-digits are stripped; the leading digits are clipped to the range's
    /// upper bound so the field can't blow past 9999,99 etc.
    private func parseHundredths(_ raw: String, range: ClosedRange<Int>) -> Int {
        let digits = raw.filter(\.isNumber)
        let maxDigits = String(range.upperBound).count
        let capped = String(digits.prefix(maxDigits))
        let parsed = Int(capped) ?? 0
        return min(range.upperBound, max(0, parsed))
    }

    private func formatHundredths(_ value: Int) -> String {
        Self.formatHundredthsStatic(value, separator: decimalSeparator)
    }

    private static func formatHundredthsStatic(_ value: Int, separator: String) -> String {
        let v = max(0, value)
        let intPart = v / 100
        let fracPart = v % 100
        return "\(intPart)\(separator)\(String(format: "%02d", fracPart))"
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

    // MARK: - Focus navigation

    private func previousField(from current: Field?) -> Field? {
        guard let current, let idx = orderedFields.firstIndex(of: current), idx > 0 else { return nil }
        return orderedFields[idx - 1]
    }

    private func nextField(from current: Field?) -> Field? {
        guard let current, let idx = orderedFields.firstIndex(of: current), idx < orderedFields.count - 1 else { return nil }
        return orderedFields[idx + 1]
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

#if DEBUG
private struct PenCalculatorPreviewHost: View {
    @State private var totalDoses: Int = 0
    @State private var clicksPerDose: Int = 0
    @State private var doseMg: Double = 0
    var body: some View {
        PenCalculatorSheet(
            accent: DLAccent.sage.color,
            totalDoses: $totalDoses,
            clicksPerDose: $clicksPerDose,
            doseMg: $doseMg
        )
    }
}

#Preview {
    PenCalculatorPreviewHost()
}
#endif
