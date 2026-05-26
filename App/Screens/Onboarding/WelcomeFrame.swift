import SwiftUI
import DoseCore

struct WelcomeFrame: View {
    let advance: () -> Void
    private let accent = DLAccent.lavender.color

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 18)
                DLRing(progress: 0.75, size: 220, stroke: 12, color: accent) {
                    VStack(spacing: 2) {
                        Text("23").font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(DL.text)
                        Text("days left").font(DL.Text.footnote13).foregroundStyle(DL.text2)
                    }
                }
            }
            Spacer()
            VStack(spacing: 14) {
                Text("Know what's left,\nbefore it runs out.")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text)
                Text("A quiet tracker for inhalers, drops,\nand daily tablets.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            PrimaryButton(title: "Get started", accent: accent, action: advance)
                .padding(.horizontal, 32)
                .padding(.bottom, 84)
        }
    }
}

#if DEBUG
#Preview {
    WelcomeFrame(advance: {})
        .background(DL.bg)
}
#endif
