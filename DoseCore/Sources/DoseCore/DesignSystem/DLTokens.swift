#if canImport(SwiftUI)
import SwiftUI

/// DoseLeft design tokens — ported from the design bundle's `tokens.jsx`.
/// Brand: soft, modern, quietly competent. No medical iconography, no gradients,
/// no heavy shadows, no glassmorphism, no red warnings.
public enum DL {

    // MARK: Surfaces
    public enum Light {
        public static let bg        = Color(hex: 0xFAFAF7)
        public static let surface   = Color.white
        public static let text      = Color(hex: 0x1A1A1C)
        public static let text2     = Color(hex: 0x8A8A8E)
        public static let text3     = Color(hex: 0xB8B8BC)
        public static let separator = Color(hex: 0xE5E5E0)
        public static let fill      = Color(hex: 0xF0F0EB)
        public static let tertiary  = Color(hex: 0xD5D5CF)
    }

    public enum Dark {
        public static let bg        = Color(hex: 0x18181A)
        public static let surface   = Color(hex: 0x1F1F22)
        public static let text      = Color(hex: 0xF2F2F0)
        public static let text2     = Color(hex: 0x8A8A8E)
        public static let text3     = Color(hex: 0x5A5A5E)
        public static let separator = Color(hex: 0x2C2C2E)
        public static let fill      = Color(hex: 0x222226)
        public static let tertiary  = Color(hex: 0x3A3A3E)
    }

    // MARK: Adaptive surface colors
    public static let bg        = Color.dlAdaptive(light: Light.bg, dark: Dark.bg)
    public static let surface   = Color.dlAdaptive(light: Light.surface, dark: Dark.surface)
    public static let text      = Color.dlAdaptive(light: Light.text, dark: Dark.text)
    public static let text2     = Color.dlAdaptive(light: Light.text2, dark: Dark.text2)
    public static let text3     = Color.dlAdaptive(light: Light.text3, dark: Dark.text3)
    public static let separator = Color.dlAdaptive(light: Light.separator, dark: Dark.separator)
    public static let fill      = Color.dlAdaptive(light: Light.fill, dark: Dark.fill)

    // MARK: Type — SF Pro Rounded for all numbers, default for everything else
    public enum Numerals {
        public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }
        public static let hero96   = display(96, weight: .bold)
        public static let title28  = display(28, weight: .bold)
        public static let stepper22 = display(22, weight: .bold)
        public static let row17    = display(17, weight: .semibold)
        public static let mini11   = display(11, weight: .semibold)
    }

    public enum Text {
        public static let largeTitle = Font.system(size: 34, weight: .bold).leading(.tight)
        public static let title22    = Font.system(size: 22, weight: .semibold)
        public static let headline17 = Font.system(size: 17, weight: .semibold)
        public static let body17     = Font.system(size: 17, weight: .regular)
        public static let subhead15  = Font.system(size: 15, weight: .regular)
        public static let footnote13 = Font.system(size: 13, weight: .regular)
        public static let caption12  = Font.system(size: 12, weight: .regular)
        public static let caption11  = Font.system(size: 11, weight: .semibold)
    }
}

// MARK: - Hex helpers

public extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }

    static func dlAdaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        // watchOS is always dark; the watch app uses the dark palette directly.
        return dark
        #endif
    }
}
#endif
