import AppIntents

struct DoseLeftShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDoseIntent(),
            phrases: [
                "Log \(.applicationName)",
                "Log a dose with \(.applicationName)",
                "Track a dose in \(.applicationName)",
            ],
            shortTitle: "Log dose",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: LogMissedIntent(),
            phrases: [
                "Mark a dose missed in \(.applicationName)",
                "I missed a dose in \(.applicationName)",
            ],
            shortTitle: "Mark missed",
            systemImageName: "exclamationmark.circle.fill"
        )
        AppShortcut(
            intent: GetRemainingIntent(),
            phrases: [
                "How much medication is left in \(.applicationName)",
                "Check \(.applicationName)",
            ],
            shortTitle: "How much is left",
            systemImageName: "circle.dashed"
        )
    }
}
