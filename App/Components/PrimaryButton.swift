import SwiftUI
import DoseCore

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: { Haptic.tap(.light); action() }) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(DL.Text.headline17)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DL.Text.headline17)
                .foregroundStyle(DL.text)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(DL.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
