#if canImport(UserNotifications)
import Foundation
import UserNotifications

/// Rebuilds the pending-notification set on every relevant write so that
/// projections stay accurate even after long app absences. UNCalendarNotificationTrigger
/// fires without the app running, which is the entire point.
public actor NotificationScheduler {
    public static let shared = NotificationScheduler()

    private let lowID = "doseleft.low"
    private let refillID = "doseleft.refill"
    private let manualID = "doseleft.manual"
    private let center: UNUserNotificationCenter

    /// Global Time-sensitive interruption-level toggle, read from UserDefaults.
    /// `nil` defaults to `true` (matches the Settings toggle's default-on state).
    private var timeSensitiveEnabled: Bool {
        let raw = UserDefaults.standard.object(forKey: "timeSensitive") as? Bool
        return raw ?? true
    }

    /// Global Sound toggle from Settings. Default-on.
    private var soundEnabled: Bool {
        let raw = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool
        return raw ?? true
    }

    private var interruptionLevel: UNNotificationInterruptionLevel {
        timeSensitiveEnabled ? .timeSensitive : .active
    }

    private var sound: UNNotificationSound? {
        soundEnabled ? .default : nil
    }

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorizationIfNeeded() async throws -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            // `.timeSensitive` was deprecated in iOS 15 in favor of the
            // `com.apple.developer.usernotifications.time-sensitive` entitlement.
            // The interruption level on each notification still controls priority.
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        @unknown default:
            return false
        }
    }

    /// Cancel every pending notification we own for a single medication.
    /// Called when the user deletes a medication.
    public func cancelAll(forMedicationID id: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let suffix = id.uuidString
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("doseleft.") && $0.contains(suffix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Cancel everything we own and re-register based on the current state of `meds`.
    /// Call after any create/edit/log/reset. Each notification family is gated
    /// by its own per-medication flag.
    public func rescheduleAll(meds: [Medication], now: Date = .now, calendar: Calendar = .current) async {
        let allPending = await center.pendingNotificationRequests()
        let ours = allPending.filter { $0.identifier.hasPrefix("doseleft.") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ours)

        for med in meds where med.isActive && med.pausedAt == nil {
            if med.isAsNeeded {
                if med.runningLowNotificationEnabled {
                    await scheduleLowStockByCount(for: med, now: now, calendar: calendar)
                }
            } else {
                if med.runningLowNotificationEnabled {
                    await scheduleRunningLow(for: med, now: now, calendar: calendar)
                }
                if med.refillNowNotificationEnabled {
                    await scheduleRefillNow(for: med, now: now, calendar: calendar)
                }
                if med.doseTimeRemindersEnabled {
                    await scheduleDoseTimeReminders(for: med, calendar: calendar)
                }
            }
        }
    }

    /// Rescue meds have no usage rate, so we can't schedule a calendar trigger.
    /// Instead, evaluate the threshold on every reschedule (which happens after
    /// every log/edit/reset) and deliver an immediate notification when crossed.
    private func scheduleLowStockByCount(for med: Medication, now: Date, calendar: Calendar) async {
        let remaining = DoseMath.dosesRemaining(med: med, at: now, calendar: calendar)
        guard remaining > 0, remaining <= med.reminderLeadDoses else { return }
        let unit = MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose"
        let unitText = remaining == 1 ? unit : unit + "s"
        let content = UNMutableNotificationContent()
        content.title = "\(med.name) is running low"
        content.body = "Only \(remaining) \(unitText) left. Time to refill."
        content.interruptionLevel = interruptionLevel
        content.sound = sound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(
            identifier: "\(lowID).\(med.id.uuidString)",
            content: content, trigger: trigger
        )
        try? await center.add(req)
    }

    private func scheduleRunningLow(for med: Medication, now: Date, calendar: Calendar) async {
        guard let end = DoseMath.projectedEndDate(med: med, at: now, calendar: calendar) else { return }
        guard let fire = calendar.date(byAdding: .day, value: -med.reminderLeadDays, to: end) else { return }
        guard fire > now else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(med.name) is running low"
        content.body = "About \(med.reminderLeadDays) days remaining. Time to refill."
        content.interruptionLevel = interruptionLevel
        content.sound = sound
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(
            identifier: "\(lowID).\(med.id.uuidString)",
            content: content, trigger: trigger
        )
        try? await center.add(req)
    }

    private func scheduleRefillNow(for med: Medication, now: Date, calendar: Calendar) async {
        let rate = DoseMath.dailyDoseRate(med: med)
        guard rate > 0, let end = DoseMath.projectedEndDate(med: med, at: now, calendar: calendar) else { return }
        guard let fire = calendar.date(byAdding: .day, value: -1, to: end) else { return }
        guard fire > now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Refill \(med.name) today"
        content.body = "Less than a day's supply remaining."
        content.interruptionLevel = interruptionLevel
        content.sound = sound
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(
            identifier: "\(refillID).\(med.id.uuidString)",
            content: content, trigger: trigger
        )
        try? await center.add(req)
    }

    private func scheduleDoseTimeReminders(for med: Medication, calendar: Calendar) async {
        for schedule in med.schedulesArray {
            for weekday in schedule.weekdays {
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = schedule.timeHour
                comps.minute = schedule.timeMinute
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "Take \(med.name)"
                content.body = "\(schedule.doseCount) \(MedicationIcon(rawValue: med.iconSymbol)?.defaultUnitLabel ?? "dose")\(schedule.doseCount == 1 ? "" : "s") due."
                content.interruptionLevel = interruptionLevel
                content.sound = sound
                let req = UNNotificationRequest(
                    identifier: "\(manualID).\(med.id.uuidString).\(schedule.id.uuidString).\(weekday)",
                    content: content, trigger: trigger
                )
                try? await center.add(req)
            }
        }
    }
}
#endif
