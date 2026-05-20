#if canImport(SwiftUI)
import SwiftUI

/// The 8 muted accent colors. Each medication picks one, and it appears
/// **only** in that medication's icon background and progress ring — never in
/// chrome, never in alerts. This is what makes the app feel calm.
public enum DLAccent: String, CaseIterable, Identifiable, Sendable {
    case sage, lavender, terracotta, plum, ochre, dustyRose, slate, moss

    public var id: String { rawValue }

    public var hex: String {
        switch self {
        case .sage:       return "#9CAF88"
        case .lavender:   return "#A78BD5"
        case .terracotta: return "#C97B5F"
        case .plum:       return "#9C7A8E"
        case .ochre:      return "#C9A961"
        case .dustyRose:  return "#C49191"
        case .slate:      return "#8395A1"
        case .moss:       return "#8C9D80"
        }
    }

    public var color: Color { Color(hexString: hex)! }

    public var displayName: String {
        switch self {
        case .sage:       return "Sage"
        case .lavender:   return "Lavender"
        case .terracotta: return "Terracotta"
        case .plum:       return "Plum"
        case .ochre:      return "Ochre"
        case .dustyRose:  return "Dusty rose"
        case .slate:      return "Slate"
        case .moss:       return "Moss"
        }
    }

    public static func from(hex: String) -> DLAccent {
        let normalized = hex.uppercased().hasPrefix("#") ? hex.uppercased() : "#" + hex.uppercased()
        return allCases.first { $0.hex.uppercased() == normalized } ?? .lavender
    }
}

public extension Color {
    /// Tint of an accent — used for chip backgrounds and the "running low" banner.
    func dlTint(_ alpha: Double = 0.14) -> Color {
        self.opacity(alpha)
    }

    /// Slightly saturated + darker accent, used for the chip/banner foreground
    /// text. Ports `saturate()` from `tokens.jsx`. Never red.
    func dlSaturated() -> Color {
        #if canImport(UIKit) && !os(watchOS)
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return Color(UIColor(hue: h, saturation: min(1, s * 1.55), brightness: max(0, b - 0.10), alpha: a))
        #else
        // watchOS: skip the bump (the chip background is already accent-tinted).
        return self
        #endif
    }
}
#endif
