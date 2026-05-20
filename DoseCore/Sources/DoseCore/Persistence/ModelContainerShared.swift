import Foundation
import SwiftData

public enum DoseLeftStorage {
    public static let appGroupID = "group.com.doseleft.shared"
    public static let cloudKitContainerID = "iCloud.com.doseleft.app"

    /// UserDefaults key (stored in the App Group suite) that gates whether the
    /// SwiftData store attaches to CloudKit. Off by default — iPhone↔Watch
    /// sync uses WatchConnectivity instead, so user data never leaves their
    /// devices unless they opt in.
    public static let iCloudSyncDefaultsKey = "iCloudSyncEnabled"

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    public static var iCloudSyncEnabled: Bool {
        sharedDefaults.bool(forKey: iCloudSyncDefaultsKey)
    }

    /// Storage URL inside the App Group container so widget + watch can read
    /// the same SwiftData store. Falls back to default if the App Group isn't
    /// available (e.g. in unit tests).
    public static var storeURL: URL {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return group.appendingPathComponent("DoseLeft.store")
        }
        return URL.documentsDirectory.appendingPathComponent("DoseLeft.store")
    }
}

public extension ModelContainer {
    /// Shared container used by the app, widget extension, and watch app.
    /// Wires SwiftData → CloudKit private database via `ModelConfiguration` when
    /// the App Group + CloudKit entitlements are present AND the user has
    /// enabled iCloud sync in Settings. Otherwise opens a local-only store so
    /// iPhone↔Watch sync goes through WatchConnectivity instead.
    ///
    /// The result is cached per-process so the SwiftUI `.modelContainer(...)`
    /// modifier and the `WatchSyncCoordinator` both work against the same
    /// instance — necessary for `@Query` views to observe coordinator writes.
    static func doseLeftShared(inMemory: Bool = false) -> ModelContainer {
        if inMemory {
            return makeInMemory(schema: dlSchema)
        }
        return DoseLeftContainerCache.shared
    }

    internal static var dlSchema: Schema {
        Schema([Medication.self, DoseSchedule.self, DoseLog.self])
    }

    internal static func makeInMemory(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If even the in-memory store fails to materialise, the schema is
            // broken — fail loudly with a useful message rather than `try!`.
            fatalError("DoseLeft: failed to create in-memory ModelContainer: \(error)")
        }
    }
}

private enum DoseLeftContainerCache {
    static let shared: ModelContainer = makeContainer()

    private static func makeContainer() -> ModelContainer {
        let schema = ModelContainer.dlSchema

        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DoseLeftStorage.appGroupID) {
            let url = group.appendingPathComponent("DoseLeft.store")
            if DoseLeftStorage.iCloudSyncEnabled {
                let cloudConfig = ModelConfiguration(
                    schema: schema,
                    url: url,
                    cloudKitDatabase: .private(DoseLeftStorage.cloudKitContainerID)
                )
                if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                    return container
                }
                // CloudKit unavailable in this run (e.g. Simulator without
                // iCloud signed in). Fall through to the local-only config.
            }
            let localConfig = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
                return container
            }
        }

        // App Group unavailable — use the app's default Documents location.
        let documents = URL.documentsDirectory.appendingPathComponent("DoseLeft.store")
        let docsConfig = ModelConfiguration(schema: schema, url: documents, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [docsConfig]) {
            return container
        }

        // Last resort: in-memory.
        return ModelContainer.makeInMemory(schema: schema)
    }
}
