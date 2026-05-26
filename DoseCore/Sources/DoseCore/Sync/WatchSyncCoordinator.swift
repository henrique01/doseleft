import Foundation
import SwiftData
import os

/// NotificationCenter name posted by the app after any change to medications,
/// schedules, or logs that should be reflected on the other device. The
/// coordinator subscribes to this and pushes a fresh snapshot.
public extension Notification.Name {
    static let dlDataChanged = Notification.Name("DoseLeft.dataChanged")
}

#if os(iOS) || os(watchOS)
import WatchConnectivity

private let dlSyncLog = Logger(subsystem: "com.doseleft.app", category: "sync")

/// Owns the WCSession that mirrors the SwiftData store between iPhone and
/// Watch. Both sides push their current state via `updateApplicationContext`
/// — the receiver merges according to its role:
///
///   - **Watch** receiving an iPhone snapshot: meds + schedules are replaced
///     (iPhone is authoritative). Logs are *unioned* — never delete a Watch
///     log just because the iPhone hasn't seen it yet.
///   - **iPhone** receiving a Watch snapshot: meds + schedules are ignored.
///     Logs are unioned.
///
/// We use `updateApplicationContext` (latest-wins, system-coalesced) instead
/// of `transferUserInfo` for everything: it's resilient to process restarts
/// and timing, and works well in the paired-simulator dev loop.
public final class WatchSyncCoordinator: NSObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = WatchSyncCoordinator()

    private let container: ModelContainer
    private var session: WCSession?
    private var snapshotVersion: Int = 0
    private var lastPushedSignature: Int = 0
    private var role: Role = .iphone

    private enum Role: String { case iphone, watch }

    private override init() {
        self.container = .doseLeftShared()
        super.init()
    }

    public static func startOniPhone() {
        shared.role = .iphone
        shared.start()
    }

    public static func startOnWatch() {
        shared.role = .watch
        shared.start()
    }

    private func start() {
        guard WCSession.isSupported() else {
            dlSyncLog.notice("WCSession not supported on this device")
            return
        }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        self.session = s
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChanged),
            name: .dlDataChanged,
            object: nil
        )
        dlSyncLog.notice("WatchSyncCoordinator started as \(self.role.rawValue, privacy: .public)")
    }

    // MARK: - Triggering pushes

    @objc private func handleDataChanged() {
        Task { @MainActor in self.pushLocalState() }
    }

    // MARK: - Outgoing snapshot (both sides)

    @MainActor
    public func pushLocalState() {
        guard let session, session.activationState == .activated else {
            dlSyncLog.notice("pushLocalState skipped: session not activated (state=\(self.session?.activationState.rawValue ?? -1))")
            return
        }
        let ctx = container.mainContext
        let meds = (try? ctx.fetch(FetchDescriptor<Medication>())) ?? []
        let schedules = (try? ctx.fetch(FetchDescriptor<DoseSchedule>())) ?? []
        let logs = (try? ctx.fetch(FetchDescriptor<DoseLog>())) ?? []

        // Cheap signature so repeated saves of identical data don't spam.
        var hasher = Hasher()
        hasher.combine(meds.map(\.id))
        hasher.combine(schedules.map(\.id))
        hasher.combine(logs.map(\.id))
        hasher.combine(meds.map(\.totalDoses))
        hasher.combine(logs.map(\.doseCount))
        hasher.combine(logs.map(\.timestamp))
        let sig = hasher.finalize()
        if sig == lastPushedSignature {
            dlSyncLog.debug("pushLocalState skipped: signature unchanged")
            return
        }

        snapshotVersion &+= 1
        let snapshot = SyncSnapshot(
            medications: meds.map(MedicationDTO.init(from:)),
            schedules: schedules.map(DoseScheduleDTO.init(from:)),
            logs: logs.map(DoseLogDTO.init(from:)),
            version: snapshotVersion
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        do {
            try session.updateApplicationContext([
                SyncPayloadKey.snapshot: data,
                "role": role.rawValue,
            ])
            // Only mark this signature as sent after the push succeeds —
            // otherwise a transient failure (e.g. counterpart not yet installed)
            // gets cached as "already sent" and later retries dedupe-skip.
            lastPushedSignature = sig
            dlSyncLog.notice("pushLocalState sent v=\(self.snapshotVersion) meds=\(meds.count) schedules=\(schedules.count) logs=\(logs.count) from=\(self.role.rawValue, privacy: .public)")
        } catch {
            dlSyncLog.error("updateApplicationContext failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Watch-side: kept for API stability. Watch dose logging now just posts
    /// `.dlDataChanged` like the iPhone side and the coordinator pushes the
    /// full snapshot.
    public func pushDoseLog(_ log: DoseLog) {
        Task { @MainActor in self.pushLocalState() }
    }

    // MARK: - WCSessionDelegate

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            dlSyncLog.error("WCSession activation error: \(error.localizedDescription, privacy: .public)")
        }
        dlSyncLog.notice("WCSession activated state=\(activationState.rawValue) role=\(self.role.rawValue, privacy: .public)")
        guard activationState == .activated else { return }

        // `didReceiveApplicationContext` only fires for updates that arrive
        // *after* activation. Anything pushed before we activated sits in
        // `receivedApplicationContext` — apply it once on startup.
        let received = session.receivedApplicationContext
        if let data = received[SyncPayloadKey.snapshot] as? Data,
           let snapshot = try? JSONDecoder().decode(SyncSnapshot.self, from: data) {
            let fromRoleRaw = (received["role"] as? String) ?? "unknown"
            dlSyncLog.notice("applying cached context v=\(snapshot.version) from=\(fromRoleRaw, privacy: .public) meds=\(snapshot.medications.count) logs=\(snapshot.logs.count)")
            Task { @MainActor in self.applySnapshot(snapshot) }
        }

        Task { @MainActor in self.pushLocalState() }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    public func sessionReachabilityDidChange(_ session: WCSession) {
        dlSyncLog.notice("reachability changed: \(session.isReachable) role=\(self.role.rawValue, privacy: .public)")
        guard session.isReachable else { return }
        Task { @MainActor in self.pushLocalState() }
    }
    #else
    public func sessionReachabilityDidChange(_ session: WCSession) {
        dlSyncLog.notice("reachability changed: \(session.isReachable) role=\(self.role.rawValue, privacy: .public)")
        guard session.isReachable else { return }
        Task { @MainActor in self.pushLocalState() }
    }
    #endif

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let data = applicationContext[SyncPayloadKey.snapshot] as? Data,
              let snapshot = try? JSONDecoder().decode(SyncSnapshot.self, from: data) else { return }
        let fromRoleRaw = (applicationContext["role"] as? String) ?? "unknown"
        dlSyncLog.notice("received snapshot v=\(snapshot.version) from=\(fromRoleRaw, privacy: .public) meds=\(snapshot.medications.count) logs=\(snapshot.logs.count)")
        Task { @MainActor in
            self.applySnapshot(snapshot)
            // Reply with our own state. Guarantees the counterpart eventually
            // gets our data once the link is up, even if our earlier activation
            // push raced ahead of WC bookkeeping (e.g. isWatchAppInstalled
            // flipping true after the watch app launches).
            self.pushLocalState()
        }
    }

    // MARK: - Apply

    @MainActor
    private func applySnapshot(_ snapshot: SyncSnapshot) {
        let ctx = container.mainContext

        let existingMeds = (try? ctx.fetch(FetchDescriptor<Medication>())) ?? []
        let existingSchedules = (try? ctx.fetch(FetchDescriptor<DoseSchedule>())) ?? []
        let existingLogs = (try? ctx.fetch(FetchDescriptor<DoseLog>())) ?? []

        var medByID = Dictionary(uniqueKeysWithValues: existingMeds.map { ($0.id, $0) })
        var schedByID = Dictionary(uniqueKeysWithValues: existingSchedules.map { ($0.id, $0) })
        let logByID = Dictionary(uniqueKeysWithValues: existingLogs.map { ($0.id, $0) })

        if role == .watch {
            // iPhone is authoritative for meds + schedules — mirror its set.
            let incomingMedIDs = Set(snapshot.medications.map(\.id))
            let incomingSchedIDs = Set(snapshot.schedules.map(\.id))
            for med in existingMeds where !incomingMedIDs.contains(med.id) { ctx.delete(med) }
            for s in existingSchedules where !incomingSchedIDs.contains(s.id) { ctx.delete(s) }

            for dto in snapshot.medications {
                if let existing = medByID[dto.id] {
                    dto.apply(to: existing)
                } else {
                    let m = Medication(
                        id: dto.id,
                        name: dto.name,
                        iconSymbol: dto.iconSymbol,
                        colorHex: dto.colorHex,
                        totalDoses: dto.totalDoses,
                        startDate: dto.startDate
                    )
                    dto.apply(to: m)
                    ctx.insert(m)
                    medByID[dto.id] = m
                }
            }

            for dto in snapshot.schedules {
                let owner = medByID[dto.medicationID]
                if let existing = schedByID[dto.id] {
                    dto.apply(to: existing)
                    existing.medication = owner
                } else {
                    let s = DoseSchedule(
                        id: dto.id,
                        timeHour: dto.timeHour,
                        timeMinute: dto.timeMinute,
                        doseCount: dto.doseCount,
                        weekdays: dto.weekdays,
                        medication: owner
                    )
                    ctx.insert(s)
                    schedByID[dto.id] = s
                }
            }
        }
        // iPhone side: ignore meds/schedules from Watch — iPhone is the source
        // of truth. Only the logs union below matters.

        // Logs union: never delete a log just because the other side hasn't
        // seen it yet. Insert anything new, update anything that already exists.
        for dto in snapshot.logs {
            let owner = medByID[dto.medicationID]
            if let existing = logByID[dto.id] {
                dto.apply(to: existing)
                existing.medication = owner
            } else {
                let log = DoseLog(
                    id: dto.id,
                    timestamp: dto.timestamp,
                    doseCount: dto.doseCount,
                    source: LogSource(rawValue: dto.sourceRaw) ?? .manual,
                    medication: owner
                )
                ctx.insert(log)
            }
        }

        do {
            try ctx.save()
            dlSyncLog.notice("applySnapshot saved")
        } catch {
            dlSyncLog.error("applySnapshot save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#else

// Stub for platforms without WatchConnectivity (macOS preview/test builds).
public enum WatchSyncCoordinator {
    public static func startOniPhone() {}
    public static func startOnWatch() {}
    public static let shared = Stub()
    public final class Stub {
        public func pushDoseLog(_ log: DoseLog) {}
        @MainActor public func pushLocalState() {}
    }
}

#endif
