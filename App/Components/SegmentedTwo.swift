import SwiftUI
import DoseCore

/// Two-option segmented control matching the design's tracking-mode picker:
/// rounded fill background, selected item gets a white pill with a hairline shadow.
struct SegmentedTwo<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(Value, String)]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0) { value, label in
                Button {
                    Haptic.tap(.light)
                    selection = value
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selection == value ? DL.text : DL.text2)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            selection == value
                                ? AnyView(RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1))
                                : AnyView(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(DL.fill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
