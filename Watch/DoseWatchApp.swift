import SwiftUI
import SwiftData
import DoseCore

@main
struct DoseWatchApp: App {
    init() {
        WatchSyncCoordinator.startOnWatch()
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        .modelContainer(.doseLeftShared())
    }
}
