import SwiftUI
import DoseCore

struct ActivityRow: View {
    let timestamp: Date
    let displayText: String
    let source: LogSource
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
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
