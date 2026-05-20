import Foundation
import SwiftData

@Model
public final class Medication {
    // CloudKit-compatible SwiftData: every stored property has a default
    // value and `@Attribute(.unique)` is omitted. Relationships are optional
    // (CloudKit cannot represent NOT-NULL to-many edges).
    public var id: UUID = UUID()
    public var name: String = ""
    public var iconSymbol: String = MedicationIcon.pills.symbolName
    public var colorHex: String = "#A78BD5"
    /// Stored medication form (Tablet, Inhaler, …). Drives unit labels and the
    /// default icon. Defaults to `tablet` for back-compat — meds saved before
    /// this field existed will read `"tablet"` here and the edit screen
    /// re-derives form from `iconSymbol` on first hydration.
    public var formRaw: String = MedicationForm.tablet.rawValue
    public var totalDoses: Int = 0
    public var startDate: Date = Date()
    public var trackingModeRaw: String = TrackingMode.automatic.rawValue
    public var reminderLeadDays: Int = 7
    public var isAsNeeded: Bool = false
    public var reminderLeadDoses: Int = 5
    /// When true, fire a local notification at every scheduled dose time so the
    /// user is reminded to take the medication. Independent of `trackingMode`
    /// — manual users typically want this on (to remember to log), and
    /// automatic users may want it on as a take-your-pill nudge.
    public var doseTimeRemindersEnabled: Bool = false
    /// When true, fire the "Running low" notification `reminderLeadDays` before
    /// the projected end (or when the rescue stock drops to `reminderLeadDoses`).
    public var runningLowNotificationEnabled: Bool = true
    /// When true, fire the "Refill now" notification ~1 day before empty. Only
    /// applies to scheduled meds — rescue meds ignore this.
    public var refillNowNotificationEnabled: Bool = true
    public var isActive: Bool = true
    public var createdAt: Date = Date()
    /// Click-pen support. When > 0 this medication is a click-dialed pen
    /// (compounded tirzepatide / semaglutide style). The number of clicks
    /// dialed per logged dose; display surfaces multiply schedule counts by
    /// this value and swap the unit label to "click". Default 0 = not a pen.
    public var clicksPerDose: Int = 0
    /// Cosmetic only: the prescribed dose in milligrams. Surfaced on the
    /// detail screen as "Dose · X mg (Y clicks)" alongside `clicksPerDose`.
    /// Default 0 = unset / not displayed.
    public var doseMg: Double = 0
    /// When non-nil, the medication is paused at that moment. Scheduled dose
    /// consumption freezes at `pausedAt` and notifications stop firing. On
    /// resume, `startDate` is shifted forward by the paused duration so the
    /// [startDate, now] window is the same length as the unpaused portion.
    public var pausedAt: Date? = nil

    @Relationship(deleteRule: .cascade, inverse: \DoseSchedule.medication)
    public var schedules: [DoseSchedule]?

    @Relationship(deleteRule: .cascade, inverse: \DoseLog.medication)
    public var logs: [DoseLog]?

    public init(
        id: UUID = UUID(),
        name: String,
        iconSymbol: String,
        colorHex: String,
        totalDoses: Int,
        startDate: Date = .now,
        trackingMode: TrackingMode = .automatic,
        reminderLeadDays: Int = 7,
        isAsNeeded: Bool = false,
        reminderLeadDoses: Int = 5,
        doseTimeRemindersEnabled: Bool = false,
        runningLowNotificationEnabled: Bool = true,
        refillNowNotificationEnabled: Bool = true,
        isActive: Bool = true,
        createdAt: Date = .now,
        pausedAt: Date? = nil,
        clicksPerDose: Int = 0,
        doseMg: Double = 0,
        form: MedicationForm? = nil
    ) {
        self.id = id
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.formRaw = (form ?? MedicationForm.inferred(fromIcon: iconSymbol)).rawValue
        self.totalDoses = totalDoses
        self.startDate = startDate
        self.trackingModeRaw = trackingMode.rawValue
        self.reminderLeadDays = reminderLeadDays
        self.isAsNeeded = isAsNeeded
        self.reminderLeadDoses = reminderLeadDoses
        // Default ON for manual mode (matches prior behavior: manual users
        // always got dose-time reminders to prompt logging) and OFF for
        // automatic. The user can flip it from the edit screen.
        self.doseTimeRemindersEnabled = doseTimeRemindersEnabled || (trackingMode == .manual)
        self.runningLowNotificationEnabled = runningLowNotificationEnabled
        self.refillNowNotificationEnabled = refillNowNotificationEnabled
        self.isActive = isActive
        self.createdAt = createdAt
        self.pausedAt = pausedAt
        self.clicksPerDose = clicksPerDose
        self.doseMg = doseMg
    }

    public var isPaused: Bool { pausedAt != nil }

    /// True when this medication is configured as a click-dialed pen.
    public var isClickPen: Bool { clicksPerDose > 0 }

    /// Pause at `now`. Subsequent dose math clamps at `pausedAt`. Idempotent —
    /// re-pausing while already paused is a no-op.
    public func pause(at now: Date = .now) {
        guard pausedAt == nil else { return }
        pausedAt = now
    }

    /// Resume at `now`. Shifts `startDate` forward by the paused duration so
    /// the scheduled-dose window stays the same length as the unpaused portion.
    /// No-op if not currently paused.
    public func resume(at now: Date = .now) {
        guard let paused = pausedAt else { return }
        let pausedFor = max(0, now.timeIntervalSince(paused))
        startDate = startDate.addingTimeInterval(pausedFor)
        pausedAt = nil
    }

    public var trackingMode: TrackingMode {
        get { TrackingMode(rawValue: trackingModeRaw) ?? .automatic }
        set { trackingModeRaw = newValue.rawValue }
    }

    /// Semantic form (Tablet, Inhaler, …). Falls back to inferring from the
    /// stored `iconSymbol` for meds created before the field existed.
    public var form: MedicationForm {
        get {
            if let f = MedicationForm(rawValue: formRaw) { return f }
            return MedicationForm.inferred(fromIcon: iconSymbol)
        }
        set { formRaw = newValue.rawValue }
    }

    /// Singular-or-plural unit label for `count` items of this medication
    /// ("1 tablet" / "3 tablets"). Click pens always report doses for the
    /// remaining-stock display; the click count belongs on schedule rows.
    public func unitLabel(for count: Int) -> String {
        if isClickPen { return count == 1 ? "dose" : "doses" }
        let base = form.defaultUnitLabel
        return count == 1 ? base : base + "s"
    }

    /// Non-optional view of `schedules` for ergonomic call sites.
    public var schedulesArray: [DoseSchedule] {
        get { schedules ?? [] }
        set { schedules = newValue }
    }

    public var logsArray: [DoseLog] {
        get { logs ?? [] }
        set { logs = newValue }
    }
}
