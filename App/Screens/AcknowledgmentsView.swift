import SwiftUI
import DoseCore

struct AcknowledgmentsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                section("Medical Disclaimer") {
                    Text("DoseLeft is a tracking tool and does not provide medical advice. Always consult your healthcare provider for dosing decisions.")
                        .font(DL.Text.subhead15)
                        .foregroundStyle(DL.text)
                        .padding(16)
                        .fixedSize(horizontal: false, vertical: true)
                }
                section("Symbols") {
                    Text("Icons by Apple — SF Symbols.")
                        .font(DL.Text.subhead15)
                        .foregroundStyle(DL.text)
                        .padding(16)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 40)
            }
        }
        .background(DL.bg.ignoresSafeArea())
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(DL.text2)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20).padding(.bottom, 8)
        VStack(spacing: 0, content: content)
            .background(DL.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AcknowledgmentsView()
    }
}
#endif
