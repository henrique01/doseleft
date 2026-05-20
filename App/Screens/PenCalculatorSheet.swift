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

    @State private var penVolumeML: Double
    @State private var concentrationMgPerML: Double
    @State private var doseMgInput: Double
    @State private var unitsPerML: Int

    @FocusState private var focused: Field?
    private enum Field: Hashable { case volume, concentration, dose }

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
        let initialDoses = max(0, totalDoses.wrappedValue)
        // Sensible defaults: 3 mL pen at 100 units/mL is the KwikPen norm.
        self._penVolumeML = State(initialValue: 3.0)
        self._concentrationMgPerML = State(
            initialValue: (initialDose > 0 && initialClicks > 0)
                ? (initialDose / Double(initialClicks)) * 100.0
                : 10.0
        )
        self._doseMgInput = State(initialValue: initialDose > 0 ? initialDose : 5.0)
        self._unitsPerML = State(initialValue: 100)
        _ = initialDoses // unused: totalDoses is fully derived from the other inputs
    }

    // MARK: - Derived

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
        section("Pen") {
            VStack(spacing: 0) {
                decimalRow(title: "Pen volume", unit: "mL", value: $penVolumeML, field: .volume)
                Divider().padding(.leading, 16)
                decimalRow(title: "Concentration", unit: "mg/mL", value: $concentrationMgPerML, field: .concentration)
                Divider().padding(.leading, 16)
                decimalRow(title: "Prescribed dose", unit: "mg", value: $doseMgInput, field: .dose)
                Divider().padding(.leading, 16)
                HStack {
                    Text("Units per mL").font(DL.Text.body17).foregroundStyle(DL.text)
                    Spacer()
                    PillStepper(value: $unitsPerML, range: 10...500, size: .small, editable: true)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 54)
            }
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

    @ViewBuilder
    private func decimalRow(title: String, unit: String, value: Binding<Double>, field: Field) -> some View {
        HStack(spacing: 8) {
            Text(title).font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            TextField("", value: value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(DL.Numerals.row17)
                .foregroundStyle(DL.text)
                .frame(minWidth: 60)
                .focused($focused, equals: field)
            Text(unit)
                .font(DL.Text.subhead15)
                .foregroundStyle(DL.text2)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        .onTapGesture { focused = field }
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
