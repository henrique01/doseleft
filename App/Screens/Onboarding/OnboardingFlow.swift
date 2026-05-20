import SwiftUI
import DoseCore

struct OnboardingFlow: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            DL.bg.ignoresSafeArea()
            TabView(selection: $page) {
                WelcomeFrame(advance: { page = 1 }).tag(0)
                PrivacyFrame(advance: { page = 2 }).tag(1)
                NotificationsFrame(finish: onFinish).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            VStack {
                Spacer()
                pageIndicator
                    .padding(.bottom, 30)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == page ? DL.text : DL.Light.tertiary)
                    .frame(width: i == page ? 18 : 6, height: 6)
                    .animation(.easeOut(duration: 0.2), value: page)
            }
        }
    }
}
