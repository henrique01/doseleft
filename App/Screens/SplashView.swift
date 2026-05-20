import SwiftUI
import DoseCore

/// SwiftUI-rendered splash: DLRing + wordmark on the brand background.
/// UILaunchScreen paints the bg colour during the cold-launch frame, then
/// this view fades into the app content.
struct SplashView: View {
    private let accent = DLAccent.lavender.color

    var body: some View {
        ZStack {
            DL.Light.bg.ignoresSafeArea()
            VStack(spacing: 32) {
                DLRing(progress: 0.70, size: 180, stroke: 16, color: accent, animate: false) {
                    EmptyView()
                }
                Text("DoseLeft")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(DL.Light.text)
                    .tracking(-0.5)
            }
            .offset(y: -20)
        }
    }
}

#if DEBUG
#Preview {
    SplashView()
}
#endif
