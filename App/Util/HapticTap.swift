import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Haptic {
    static func tap(_ style: HapticStyle = .light) {
        #if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: style.uiStyle)
        g.prepare()
        g.impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

enum HapticStyle {
    case light, medium, soft

    #if canImport(UIKit)
    var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light:  return .light
        case .medium: return .medium
        case .soft:   return .soft
        }
    }
    #endif
}
