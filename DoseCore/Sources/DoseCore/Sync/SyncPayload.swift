import Foundation

/// Codable mirrors of the SwiftData models used for iPhone↔Watch transport
/// over WatchConnectivity. Kept intentionally separate from the `@Model`
/// classes so the wire format is stable independent of SwiftData attributes.
public struct MedicationDTO: Codable, Sendable, Hashable {
    public var id: UUID
    public var name: String
    public var iconSymbol: String
    public var colorHex: String
    public var totalDoses: Int
    public var startDate: Date
    public var trackingModeRaw: String
    public var reminderLeadDays: Int
    public var isAsNeeded: Bool
    public var reminderLeadDoses: Int
    public var doseTimeRemindersEnabled: Bool
    public var runningLowNotificationEnabled: Bool
    public var refillNowNotificationEnabled: Bool
    public var isActive: Bool
    public var createdAt: Date
    public var pausedAt: Date?
    /// Optional so older peers that don't send this field still decode; the
    /// receiver infers form from `iconSymbol` when absent.
    public var formRaw: String?

    public init(from m: Medication) {
        self.id = m.id
        self.name = m.name
        self.iconSymbol = m.iconSymbol
        self.colorHex = m.colorHex
        self.totalDoses = m.totalDoses
        self.startDate = m.startDate
        self.trackingModeRaw = m.trackingModeRaw
        self.reminderLeadDays = m.reminderLeadDays
        self.isAsNeeded = m.isAsNeeded
        self.reminderLeadDoses = m.reminderLeadDoses
        self.doseTimeRemindersEnabled = m.doseTimeRemindersEnabled
        self.runningLowNotificationEnabled = m.runningLowNotificationEnabled
        self.refillNowNotificationEnabled = m.refillNowNotificationEnabled
        self.isActive = m.isActive
        self.createdAt = m.createdAt
        self.pausedAt = m.pausedAt
        self.formRaw = m.formRaw
    }

    /// Apply this DTO's fields onto an existing `Medication`. Caller chooses
    /// whether the target was just inserted or already existed.
    public func apply(to m: Medication) {
        m.id = id
        m.name = name
        m.iconSymbol = iconSymbol
        m.colorHex = colorHex
        m.totalDoses = totalDoses
        m.startDate = startDate
        m.trackingModeRaw = trackingModeRaw
        m.reminderLeadDays = reminderLeadDays
        m.isAsNeeded = isAsNeeded
        m.reminderLeadDoses = reminderLeadDoses
        m.doseTimeRemindersEnabled = doseTimeRemindersEnabled
        m.runningLowNotificationEnabled = runningLowNotificationEnabled
        m.refillNowNotificationEnabled = refillNowNotificationEnabled
        m.isActive = isActive
        m.createdAt = createdAt
        m.pausedAt = pausedAt
        m.formRaw = formRaw ?? MedicationForm.inferred(fromIcon: iconSymbol).rawValue
    }
}

public struct DoseScheduleDTO: Codable, Sendable, Hashable {
    public var id: UUID
    public var medicationID: UUID
    public var timeHour: Int
    public var timeMinute: Int
    public var doseCount: Int
    public var weekdays: [Int]

    public init(from s: DoseSchedule) {
        self.id = s.id
        self.medicationID = s.medication?.id ?? UUID()
        self.timeHour = s.timeHour
        self.timeMinute = s.timeMinute
        self.doseCount = s.doseCount
        self.weekdays = s.weekdays
    }

    public func apply(to s: DoseSchedule) {
        s.id = id
        s.timeHour = timeHour
        s.timeMinute = timeMinute
        s.doseCount = doseCount
        s.weekdays = weekdays
    }
}

public struct DoseLogDTO: Codable, Sendable, Hashable {
    public var id: UUID
    public var medicationID: UUID
    public var timestamp: Date
    public var doseCount: Int
    public var sourceRaw: String

    public init(from log: DoseLog) {
        self.id = log.id
        self.medicationID = log.medication?.id ?? UUID()
        self.timestamp = log.timestamp
        self.doseCount = log.doseCount
        self.sourceRaw = log.sourceRaw
    }

    public func apply(to log: DoseLog) {
        log.id = id
        log.timestamp = timestamp
        log.doseCount = doseCount
        log.sourceRaw = sourceRaw
    }
}

/// Full-state snapshot sent over WCSession's `updateApplicationContext`. The
/// receiver replaces the local store contents (additive upsert + tombstone
/// pruning) to match.
public struct SyncSnapshot: Codable, Sendable {
    public var medications: [MedicationDTO]
    public var schedules: [DoseScheduleDTO]
    public var logs: [DoseLogDTO]
    /// Monotonically increasing version so the receiver can ignore stale
    /// snapshots that arrive out of order.
    public var version: Int

    public init(medications: [MedicationDTO], schedules: [DoseScheduleDTO], logs: [DoseLogDTO], version: Int) {
        self.medications = medications
        self.schedules = schedules
        self.logs = logs
        self.version = version
    }
}

/// One-shot messages sent via `transferUserInfo` for events that must not be
/// lost (e.g. a dose logged on the Watch).
public enum SyncEvent: Codable, Sendable {
    case doseLogAppended(DoseLogDTO)
}

public enum SyncPayloadKey {
    public static let snapshot = "dlSnapshot"
    public static let event = "dlEvent"
    public static let request = "dlRequest"
}

public enum SyncRequest {
    public static let fullSnapshot = "fullSnapshot"
}
