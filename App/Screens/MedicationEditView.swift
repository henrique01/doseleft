import SwiftUI
import SwiftData
import WidgetKit
import DoseCore

struct MedicationEditView: View {
    let existing: Medication?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var form: MedicationForm = .pen
    @State private var iconSymbol: String = MedicationForm.pen.defaultIcon
    @State private var accent: DLAccent = .lavender
    // Pen-by-default starts at 0 — the pen calculator fills this in. The
    // onChange below restores a sensible default if the user switches off pen.
    @State private var totalDoses: Int = 0
    @State private var trackingMode: TrackingMode = .automatic
    @State private var reminderLead: Int = 7
    @State private var isAsNeeded: Bool = false
    @State private var reminderLeadDoses: Int = 5
    @State private var doseTimeRemindersEnabled: Bool = false
    @State private var runningLowEnabled: Bool = true
    @State private var refillNowEnabled: Bool = true
    @State private var schedules: [ScheduleDraft] = [.defaultEvening()]
    @State private var startDate: Date = .now
    @State private var editingScheduleID: UUID?
    @State private var confirmDelete = false
    @State private var showingFormPicker = false
    @State private var showingIconPicker = false
    // Click-pen state. clicksPerDose == 0 means "not a pen" — when the user
    // picks the Pen form the calculator sheet fills these in.
    @State private var clicksPerDose: Int = 0
    @State private var doseMg: Double = 0
    @State private var showingPenCalc: Bool = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && totalDoses > 0
            && (isAsNeeded || !schedules.isEmpty)
            // Pen form requires the calculator to have set clicksPerDose.
            && (form != .pen || clicksPerDose > 0)
    }

    private enum MedicationType: Hashable { case scheduled, asNeeded }
    private var medicationType: Binding<MedicationType> {
        Binding(
            get: { isAsNeeded ? .asNeeded : .scheduled },
            set: { isAsNeeded = ($0 == .asNeeded) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    formAndColorCard
                    if form == .pen {
                        section("Pen") {
                            penCalculatorRow
                        }
                        section("Doses in pen") {
                            HStack {
                                Text("Doses")
                                    .font(DL.Text.subhead15)
                                    .foregroundStyle(DL.text2)
                                Spacer()
                                Text(totalDoses > 0 ? "\(totalDoses)" : "—")
                                    .font(DL.Numerals.row17)
                                    .foregroundStyle(DL.text)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 60)
                        }
                    } else {
                        section("Total doses in container") {
                            HStack {
                                Text(form.defaultUnitLabel.capitalized + "s")
                                    .font(DL.Text.subhead15)
                                    .foregroundStyle(DL.text2)
                                Spacer()
                                PillStepper(value: $totalDoses, range: 1...9999, size: .large, editable: true)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 60)
                        }
                    }
                    section("Start date") {
                        DatePicker(
                            "Started",
                            selection: $startDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .tint(accent.color)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                    }
                    section("Type") {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("How it's taken").font(DL.Text.body17).foregroundStyle(DL.text)
                                Text("Rescue meds are taken only when needed.")
                                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            Divider().padding(.leading, 16)
                            Picker("", selection: medicationType) {
                                Text("Scheduled").tag(MedicationType.scheduled)
                                Text("As needed").tag(MedicationType.asNeeded)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        }
                    }
                    if !isAsNeeded {
                        section("Tracking") {
                            VStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mode").font(DL.Text.body17).foregroundStyle(DL.text)
                                    Text("Automatic counts from your schedule.")
                                        .font(DL.Text.footnote13).foregroundStyle(DL.text2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                Divider().padding(.leading, 16)
                                Picker("", selection: $trackingMode) {
                                    Text("Automatic").tag(TrackingMode.automatic)
                                    Text("Manual").tag(TrackingMode.manual)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                        }
                    }
                    if !isAsNeeded {
                    section("Schedule") {
                        VStack(spacing: 0) {
                            ForEach(Array(schedules.enumerated()), id: \.element.id) { idx, s in
                                scheduleRow(s, at: idx)
                                if idx < schedules.count - 1 { Divider().padding(.leading, 16) }
                            }
                            Divider().padding(.leading, 16)
                            Button {
                                let draft = ScheduleDraft.defaultEvening()
                                schedules.append(draft)
                                editingScheduleID = draft.id
                            } label: {
                                HStack {
                                    Text("+ Add another time")
                                        .font(DL.Text.body17)
                                        .foregroundStyle(accent.color)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    }
                    section("Remind me") {
                        VStack(spacing: 0) {
                            if isAsNeeded {
                                lowStockToggleRow
                                Divider().padding(.leading, 16)
                                stepperRow(
                                    title: "Doses left",
                                    binding: $reminderLeadDoses,
                                    range: 1...100,
                                    enabled: runningLowEnabled
                                )
                            } else {
                                runningLowToggleRow
                                Divider().padding(.leading, 16)
                                stepperRow(
                                    title: "Days before empty",
                                    binding: $reminderLead,
                                    range: 1...30,
                                    enabled: runningLowEnabled
                                )
                                Divider().padding(.leading, 16)
                                refillNowToggleRow
                                Divider().padding(.leading, 16)
                                doseTimeToggleRow
                            }
                        }
                    }
                    if existing != nil {
                        deleteMedicationButton.padding(.top, 20)
                    }
                    Spacer(minLength: 32)
                }
            }
            .background(DL.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New medication" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(DL.text2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? accent.color : DL.text3)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        // Resign first responder for any focused text field/number pad.
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(accent.color)
                }
            }
            .sheet(item: Binding<ScheduleEditTarget?>(
                get: { editingScheduleID.map { ScheduleEditTarget(id: $0) } },
                set: { editingScheduleID = $0?.id }
            )) { target in
                let targetID = target.id
                let binding = Binding<ScheduleDraft>(
                    get: { schedules.first(where: { $0.id == targetID }) ?? .defaultEvening() },
                    set: { newValue in
                        if let i = schedules.firstIndex(where: { $0.id == targetID }) {
                            schedules[i] = newValue
                        }
                    }
                )
                ScheduleEditView(
                    schedule: binding,
                    accent: accent.color,
                    // Only allow deletion when at least one schedule will remain.
                    onDelete: schedules.count > 1 ? { removeSchedule(id: targetID) } : nil
                )
            }
        }
        .tint(accent.color)
        .onAppear(perform: hydrate)
        .onChange(of: form) { oldValue, newValue in
            // Leaving the pen form clears pen-specific config; entering it
            // resets totalDoses so the calculator owns that value.
            if newValue != .pen {
                clicksPerDose = 0
                doseMg = 0
                // If we're leaving pen with the calc-owned 0, hand the user
                // a sensible non-zero starting point for the regular stepper.
                if oldValue == .pen && totalDoses == 0 {
                    totalDoses = 30
                }
            } else if clicksPerDose == 0 {
                totalDoses = 0
            }
            // Form change always snaps the icon back to that form's default —
            // the user can still override it from the icon picker afterwards.
            iconSymbol = newValue.defaultIcon
        }
        .sheet(isPresented: $showingPenCalc) {
            PenCalculatorSheet(
                accent: accent.color,
                totalDoses: $totalDoses,
                clicksPerDose: $clicksPerDose,
                doseMg: $doseMg
            )
        }
        .sheet(isPresented: $showingFormPicker) {
            FormPickerSheet(selection: $form, accent: accent.color)
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerSheet(selection: $iconSymbol, form: form, accent: accent.color)
        }
        .confirmationDialog(
            "Delete \(name)?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete medication", role: .destructive) {
                deleteMedication()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the medication, its schedule, and all logged doses. This cannot be undone.")
        }
    }

    private var penCalculatorRow: some View {
        Button {
            Haptic.tap(.light)
            showingPenCalc = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if clicksPerDose > 0 {
                        Text("\(formatDoseMg(doseMg)) mg · \(clicksPerDose) clicks per dose")
                            .font(DL.Text.body17)
                            .foregroundStyle(DL.text)
                        Text("Tap to recalculate")
                            .font(DL.Text.footnote13)
                            .foregroundStyle(DL.text2)
                    } else {
                        Text("Set up your pen")
                            .font(DL.Text.body17)
                            .foregroundStyle(DL.text)
                        Text("Calculate clicks from dose and concentration")
                            .font(DL.Text.footnote13)
                            .foregroundStyle(DL.text2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DL.text3)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatDoseMg(_ value: Double) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private var deleteMedicationButton: some View {
        Button {
            Haptic.tap(.medium)
            confirmDelete = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete medication").font(DL.Text.body17)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func deleteMedication() {
        guard let existing else { return }
        let medID = existing.id
        // Cascade rules on the SwiftData relationships clean up schedules + logs.
        context.delete(existing)
        context.dlSave()
        Haptic.success()
        Task {
            // Cancel every pending notification we own for this med.
            await NotificationScheduler.shared.cancelAll(forMedicationID: medID)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    // MARK: - Reminder rows

    private var runningLowToggleRow: some View {
        Toggle(isOn: $runningLowEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Running low").font(DL.Text.body17).foregroundStyle(DL.text)
                Text("Notify me before the container is empty.")
                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
            }
        }
        .tint(accent.color)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    private var refillNowToggleRow: some View {
        Toggle(isOn: $refillNowEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Refill now").font(DL.Text.body17).foregroundStyle(DL.text)
                Text("Final reminder ~1 day before empty.")
                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
            }
        }
        .tint(accent.color)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    private var doseTimeToggleRow: some View {
        Toggle(isOn: $doseTimeRemindersEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("At each dose time").font(DL.Text.body17).foregroundStyle(DL.text)
                Text("Notify me to take this medication.")
                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
            }
        }
        .tint(accent.color)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    private var lowStockToggleRow: some View {
        Toggle(isOn: $runningLowEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Low stock").font(DL.Text.body17).foregroundStyle(DL.text)
                Text("Notify me when supply gets low.")
                    .font(DL.Text.footnote13).foregroundStyle(DL.text2)
            }
        }
        .tint(accent.color)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    @ViewBuilder
    private func stepperRow(title: String, binding: Binding<Int>, range: ClosedRange<Int>, enabled: Bool) -> some View {
        HStack {
            Text(title).font(DL.Text.body17).foregroundStyle(DL.text)
            Spacer()
            PillStepper(value: binding, range: range, size: .small)
                .disabled(!enabled)
        }
        .opacity(enabled ? 1 : 0.4)
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
    }

    // MARK: - Pickers

    @ViewBuilder
    private func scheduleRow(_ s: ScheduleDraft, at idx: Int) -> some View {
        // For click pens the schedule row reads in clicks rather than "shots":
        // "· 12 clicks · Every day" instead of "· 1 click · Every day".
        let displayCount = (form == .pen && clicksPerDose > 0)
            ? s.count * clicksPerDose
            : s.count
        Button { editingScheduleID = s.id } label: {
            HStack(spacing: 12) {
                Text(s.timeText).font(DL.Numerals.row17).foregroundStyle(DL.text)
                Text("· \(displayCount) \(s.unitLabel(for: form, count: displayCount)) · \(s.weekdayText)")
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DL.text3)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Long-press for quick removal without opening the editor.
        .contextMenu {
            if schedules.count > 1 {
                Button(role: .destructive) {
                    removeSchedule(at: idx)
                } label: {
                    Label("Remove dose time", systemImage: "trash")
                }
            }
        }
        .accessibilityAction(named: "Remove dose time") {
            if schedules.count > 1 { removeSchedule(at: idx) }
        }
    }

    private func removeSchedule(at idx: Int) {
        guard schedules.indices.contains(idx), schedules.count > 1 else { return }
        removeSchedule(id: schedules[idx].id)
    }

    private func removeSchedule(id: UUID) {
        guard schedules.count > 1 else { return }
        Haptic.tap(.medium)
        // If the editor sheet is open on this row, close it first so its
        // binding doesn't resolve against a removed entry.
        if editingScheduleID == id { editingScheduleID = nil }
        withAnimation(.easeOut(duration: 0.2)) {
            schedules.removeAll { $0.id == id }
        }
    }

    // MARK: - Hero + Form/Color

    private var heroHeader: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 96, height: 96)
                    Image(systemName: iconSymbol)
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.white)
                }
                Button {
                    Haptic.tap(.light)
                    showingIconPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 1)
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DL.text2)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: 2)
                .accessibilityLabel("Choose icon")
            }
            TextField("", text: $name, prompt: Text("Medication name").foregroundStyle(DL.text3))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DL.text)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var formAndColorCard: some View {
        VStack(spacing: 0) {
            Button {
                Haptic.tap(.light)
                showingFormPicker = true
            } label: {
                HStack {
                    Text("Form")
                        .font(DL.Text.body17)
                        .foregroundStyle(DL.text)
                    Spacer()
                    Text(form.displayName)
                        .font(DL.Text.body17)
                        .foregroundStyle(DL.text2)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DL.text3)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)

            HStack(spacing: 12) {
                Text("Color")
                    .font(DL.Text.body17)
                    .foregroundStyle(DL.text)
                Spacer(minLength: 8)
                colorPickerRow
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
        }
        .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var colorPickerRow: some View {
        HStack(spacing: 10) {
            ForEach(DLAccent.allCases) { a in
                Button {
                    Haptic.tap(.light)
                    accent = a
                } label: {
                    Circle()
                        .fill(a.color)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(a == accent ? a.color : .clear, lineWidth: 2)
                                .padding(-3)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(a.displayName)
            }
        }
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

    private func hydrate() {
        guard let existing else { return }
        name = existing.name
        // Hydrate form first; for meds saved before `formRaw` existed the
        // accessor falls back to inferring from the icon symbol.
        form = existing.form
        iconSymbol = existing.iconSymbol
        accent = DLAccent.from(hex: existing.colorHex)
        totalDoses = existing.totalDoses
        startDate = existing.startDate
        trackingMode = existing.trackingMode
        reminderLead = existing.reminderLeadDays
        isAsNeeded = existing.isAsNeeded
        reminderLeadDoses = existing.reminderLeadDoses
        doseTimeRemindersEnabled = existing.doseTimeRemindersEnabled
        runningLowEnabled = existing.runningLowNotificationEnabled
        refillNowEnabled = existing.refillNowNotificationEnabled
        schedules = existing.schedulesArray.map { ScheduleDraft(from: $0) }
        if schedules.isEmpty { schedules = [.defaultEvening()] }
        clicksPerDose = existing.clicksPerDose
        doseMg = existing.doseMg
    }

    private func save() {
        let effectiveTrackingMode: TrackingMode = isAsNeeded ? .manual : trackingMode
        let med: Medication
        if let existing {
            existing.name = name
            existing.iconSymbol = iconSymbol
            existing.form = form
            existing.colorHex = accent.hex
            existing.totalDoses = totalDoses
            existing.startDate = startDate
            existing.trackingMode = effectiveTrackingMode
            existing.reminderLeadDays = reminderLead
            existing.isAsNeeded = isAsNeeded
            existing.reminderLeadDoses = reminderLeadDoses
            existing.doseTimeRemindersEnabled = doseTimeRemindersEnabled && !isAsNeeded
            existing.runningLowNotificationEnabled = runningLowEnabled
            existing.refillNowNotificationEnabled = refillNowEnabled
            existing.clicksPerDose = form == .pen ? clicksPerDose : 0
            existing.doseMg = form == .pen ? doseMg : 0
            // Replace schedules. Rescue meds keep an empty schedule set.
            for old in existing.schedulesArray { context.delete(old) }
            existing.schedules = isAsNeeded ? [] : schedules.map { $0.toModel(medication: existing) }
            med = existing
        } else {
            med = Medication(
                name: name,
                iconSymbol: iconSymbol,
                colorHex: accent.hex,
                totalDoses: totalDoses,
                startDate: startDate,
                trackingMode: effectiveTrackingMode,
                reminderLeadDays: reminderLead,
                isAsNeeded: isAsNeeded,
                reminderLeadDoses: reminderLeadDoses,
                doseTimeRemindersEnabled: doseTimeRemindersEnabled && !isAsNeeded,
                runningLowNotificationEnabled: runningLowEnabled,
                refillNowNotificationEnabled: refillNowEnabled,
                clicksPerDose: form == .pen ? clicksPerDose : 0,
                doseMg: form == .pen ? doseMg : 0,
                form: form
            )
            context.insert(med)
            if !isAsNeeded {
                for draft in schedules {
                    let s = draft.toModel(medication: med)
                    context.insert(s)
                }
            }
        }
        context.dlSave()
        Haptic.success()
        Task {
            // If any notification family is enabled, make sure we have
            // notification permission first; otherwise nothing will fire.
            let needsAuth = med.doseTimeRemindersEnabled
                || med.runningLowNotificationEnabled
                || (!med.isAsNeeded && med.refillNowNotificationEnabled)
            if needsAuth {
                _ = try? await NotificationScheduler.shared.requestAuthorizationIfNeeded()
            }
            await NotificationScheduler.shared.rescheduleAll(meds: [med])
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

// MARK: - Drafts (form state held outside SwiftData until save)

struct ScheduleDraft: Identifiable, Hashable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var count: Int
    var weekdays: Set<Int>      // 1=Sun … 7=Sat

    static func defaultEvening() -> ScheduleDraft {
        ScheduleDraft(hour: 20, minute: 0, count: 1, weekdays: Set(1...7))
    }

    init(id: UUID = UUID(), hour: Int, minute: Int, count: Int, weekdays: Set<Int>) {
        self.id = id; self.hour = hour; self.minute = minute; self.count = count; self.weekdays = weekdays
    }

    init(from m: DoseSchedule) {
        self.id = m.id
        self.hour = m.timeHour
        self.minute = m.timeMinute
        self.count = m.doseCount
        self.weekdays = Set(m.weekdays)
    }

    func toModel(medication: Medication) -> DoseSchedule {
        DoseSchedule(
            timeHour: hour,
            timeMinute: minute,
            doseCount: count,
            weekdays: weekdays.sorted(),
            medication: medication
        )
    }

    var timeText: String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        let d = Calendar.current.date(from: c) ?? .now
        return d.formatted(.dateTime.hour().minute())
    }

    var weekdayText: String {
        Set(weekdays) == Set(1...7) ? "Every day" : "\(weekdays.count) days/wk"
    }

    func unitLabel(for form: MedicationForm) -> String {
        unitLabel(for: form, count: count)
    }

    /// Variant that pluralises against a caller-supplied count — useful when
    /// the displayed number differs from the stored `count` (e.g. click pens
    /// multiply by `clicksPerDose` for the visible label).
    func unitLabel(for form: MedicationForm, count: Int) -> String {
        let base = form.defaultUnitLabel
        return count == 1 ? base : base + "s"
    }
}

private struct ScheduleEditTarget: Identifiable {
    let id: UUID
}

#if DEBUG
private struct MedicationEditPreviewHost: View {
    let existing: Medication?
    let container: ModelContainer
    init(existing build: (() -> Medication)? = nil) {
        let c = ModelContainer.doseLeftShared(inMemory: true)
        if let build {
            let ctx = ModelContext(c)
            let m = build()
            ctx.insert(m)
            m.schedules?.forEach { ctx.insert($0) }
            try? ctx.save()
            self.existing = m
        } else {
            self.existing = nil
        }
        self.container = c
    }
    var body: some View {
        MedicationEditView(existing: existing)
            .modelContainer(container)
    }
}

#Preview("New") {
    MedicationEditPreviewHost()
}

#Preview("Edit existing") {
    MedicationEditPreviewHost { PreviewFixtures.scheduledMed() }
}
#endif
