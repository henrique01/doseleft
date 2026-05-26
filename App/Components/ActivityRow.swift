import SwiftUI
import DoseCore

struct ActivityRow: View {
    let timestamp: Date
    let displayText: String
    let source: LogSource
    let accent: Color
    var isSelectMode: Bool = false
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? accent : DL.text3)
                    .transition(.opacity)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayText)
                    .font(DL.Numerals.row17)
                    .foregroundStyle(DL.text)
                Text(timestamp.formatted(.relative(presentation: .named)))
                    .font(DL.Text.footnote13)
                    .foregroundStyle(DL.text2)
            }
            Spacer(minLength: 0)
            TagBadge(source: source, accent: accent)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.15), value: isSelectMode)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct TagBadge: View {
    let source: LogSource
    let accent: Color

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .foregroundStyle(fg)
    }

    private var label: String {
        switch source {
        case .scheduled:  return "Scheduled"
        case .manual:     return "Manual"
        case .reset:      return "Reset"
        case .correction: return "Correction"
        case .missed:     return "Missed"
        }
    }

    private var bg: Color {
        switch source {
        case .scheduled:  return Color.black.opacity(0.05)
        case .manual:     return accent.opacity(0.14)
        case .reset:      return DLAccent.ochre.color.opacity(0.16)
        case .correction: return DLAccent.plum.color.opacity(0.16)
        case .missed:     return DLAccent.plum.color.opacity(0.16)
        }
    }

    private var fg: Color {
        switch source {
        case .scheduled:  return DL.text2
        case .manual:     return accent.dlSaturated()
        case .reset:      return DLAccent.ochre.color.dlSaturated()
        case .correction: return DLAccent.plum.color.dlSaturated()
        case .missed:     return DLAccent.plum.color.dlSaturated()
        }
    }
}

#if DEBUG
#Preview("ActivityRow — scheduled") {
    ActivityRow(
        timestamp: .now.addingTimeInterval(-3600),
        displayText: "2 doses",
        source: .scheduled,
        accent: DLAccent.lavender.color
    )
    .padding()
}

#Preview("ActivityRow — manual") {
    ActivityRow(
        timestamp: .now.addingTimeInterval(-7200),
        displayText: "1 dose",
        source: .manual,
        accent: DLAccent.sage.color
    )
    .padding()
}

#Preview("TagBadge — all sources") {
    VStack(spacing: 8) {
        ForEach([LogSource.scheduled, .manual, .reset, .correction, .missed], id: \.rawValue) { source in
            TagBadge(source: source, accent: DLAccent.lavender.color)
        }
    }
    .padding()
}
#endif
