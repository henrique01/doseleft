import SwiftUI
import DoseCore

struct HomeEmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                DLRing(progress: 0, size: 120, stroke: 3,
                       color: DL.Light.tertiary,
                       trackColor: DL.Light.separator, animate: false)
                Image(systemName: "pills.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DL.Light.tertiary)
            }
            VStack(spacing: 8) {
                Text("No medications yet")
                    .font(DL.Text.title22)
                    .foregroundStyle(DL.text)
                Text("Add your first medication to start tracking what's left.")
                    .font(DL.Text.subhead15)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DL.text2)
                    .frame(maxWidth: 280)
            }
            PrimaryButton(title: "Add medication", accent: DLAccent.lavender.color, action: onAdd)
                .padding(.top, 8)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
