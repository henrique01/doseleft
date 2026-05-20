import SwiftUI
import SwiftData
import DoseCore

@main
struct DoseLeftApp: App {
    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("themePreference") private var themePreference = ThemePreference.system
    @State private var showSplash = true

    init() {
        WatchSyncCoordinator.startOniPhone()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if didOnboard {
                        HomeView()
                    } else {
                        OnboardingFlow(onFinish: { didOnboard = true })
                    }
                }
                .preferredColorScheme(themePreference.colorScheme)
                .tint(DLAccent.lavender.color)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
        .modelContainer(.doseLeftShared())
    }
}
