import SwiftUI

struct SignDetailView: View {
    let sign: RoadSign

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SignView(sign: sign, size: 160)
                    .padding(.top, 12)

                Text(sign.name)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text(sign.kind.rawValue + " sign")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Theme.accent, in: Capsule())

                infoCard(title: "Meaning", systemImage: "text.book.closed.fill", text: sign.meaning)
                infoCard(title: "Shape & color", systemImage: "paintpalette.fill", text: sign.shapeColorHint)
                infoCard(title: "Study tip", systemImage: "lightbulb.fill", text: sign.studyTip)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(sign.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoCard(title: String, systemImage: String, text: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                Text(text)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
