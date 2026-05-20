#if canImport(SwiftUI)
import SwiftUI

/// The progress ring used in app rows (36pt), detail hero (200pt), widgets,
/// watch, and onboarding. Always 3pt-equivalent stroke, rounded line cap.
/// Accent in the foreground, neutral track behind.
public struct DLRing<Content: View>: View {
    public let progress: Double
    public let size: CGFloat
    public let stroke: CGFloat
    public let color: Color
    public let trackColor: Color
    public let animate: Bool
    @ViewBuilder public let content: () -> Content

    public init(
        progress: Double,
        size: CGFloat,
        stroke: CGFloat = 3,
        color: Color,
        trackColor: Color = Color.black.opacity(0.06),
        animate: Bool = true,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.progress = progress
        self.size = size
        self.stroke = stroke
        self.color = color
        self.trackColor = trackColor
        self.animate = animate
        self.content = content
    }

    public var body: some View {
        let clamped = max(0, min(1, progress))
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(animate ? .easeOut(duration: 0.5) : nil, value: clamped)
            content()
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text("\(Int((clamped * 100).rounded())) percent remaining"))
    }
}
#endif
