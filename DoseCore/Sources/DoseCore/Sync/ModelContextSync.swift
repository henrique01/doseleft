import Foundation
import SwiftData

public extension ModelContext {
    /// Saves the context and notifies the `WatchSyncCoordinator` so any
    /// medication/schedule/log change is pushed to the other device. Use this
    /// in place of `try? context.save()` at write sites that should sync.
    func dlSave() {
        try? save()
        NotificationCenter.default.post(name: .dlDataChanged, object: nil)
    }
}
