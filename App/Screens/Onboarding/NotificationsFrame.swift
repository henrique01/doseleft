import SwiftUI
import DoseCore

struct NotificationsFrame: View {
    let finish: () -> Void
    private let accent = DLAccent.lavender.color

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            NotificationPreviewCard(accent: accent)
                .padding(.horizontal, 20)
            Spacer()
            VStack(spacing: 14) {
                Text("A nudge, a week ahead.")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text)
                Text("We'll let you know when it's time\nto refill — no surprises.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            VStack(spacing: 10) {
                PrimaryButton(title: "Allow notifications", systemImage: "bell.fill", accent: accent) {
                    Task {
                        _ = try? await NotificationScheduler.shared.requestAuthorizationIfNeeded()
                        finish()
                    }
                }
                Button("Maybe later", action: finish)
                    .font(DL.Text.headline17)
                    .foregroundStyle(DL.text2)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
    }
}

struct NotificationPreviewCard: View {
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AppIconBlock(size: 38, cornerRadius: 9)
                Text("DOSELEFT")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DL.text2)
                Spacer()
                Text("now").font(.system(size: 13)).foregroundStyle(DL.text2)
            }
            Text("Flixotide is running low")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DL.text)
                .padding(.top, 6)
            Text("About 7 days remaining. Time to refill.")
                .font(.system(size: 15))
                .foregroundStyle(DL.text)
                .padding(.top, 1)
        }
        .padding(14)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(accent.opacity(0.5), lineWidth: 1))
    }
}

/// Mini app icon used in the notification preview.
struct AppIconBlock: View {
    let size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        let accent = DLAccent.lavender.color
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DL.Light.bg)
            .frame(width: size, height: size)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
            .overlay {
                DLRing(progress: 0.70, size: size * 0.72, stroke: size * 0.07, color: accent,
                       trackColor: accent.opacity(0.18), animate: false)
            }
    }
}
