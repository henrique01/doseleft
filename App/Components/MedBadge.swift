import SwiftUI
import DoseCore

/// 44pt accent-colored circle with an SF Symbol inside. The leading element
/// for every medication row, plus icon picker, widgets, and watch.
struct MedBadge: View {
    let symbol: String
    let accent: Color
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(accent)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.45, weight: .medium))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}
