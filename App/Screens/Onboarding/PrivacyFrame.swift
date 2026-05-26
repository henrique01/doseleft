import SwiftUI
import DoseCore

struct PrivacyFrame: View {
    let advance: () -> Void
    private let accent = DLAccent.lavender.color

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .frame(width: 96, height: 96)
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DL.Light.separator, lineWidth: 0.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(DL.text)
            }
            Spacer()
            VStack(spacing: 14) {
                Text("Your data stays here.")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text)
                Text("Everything you log lives on this iPhone and Apple Watch. No accounts. No tracking. iCloud sync is off by default. Turn it on in Settings if you want it.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            PrimaryButton(title: "Continue", accent: accent, action: advance)
                .padding(.horizontal, 32)
                .padding(.bottom, 84)
        }
    }
}

#if DEBUG
#Preview {
    PrivacyFrame(advance: {})
        .background(DL.bg)
}
#endif
