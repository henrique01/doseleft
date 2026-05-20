import SwiftUI
import DoseCore

/// "Running low" chip. Accent-tinted background, slightly saturated foreground.
/// Never red — that is the whole point of `dlSaturated()` instead of a system warning color.
struct DoseChip: View {
    let title: String
    let accent: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .foregroundStyle(accent.dlSaturated())
    }
}
