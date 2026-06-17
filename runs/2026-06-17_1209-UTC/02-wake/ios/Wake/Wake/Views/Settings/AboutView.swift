import SwiftUI

/// Simple About screen.
struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                        Image(systemName: "figure.pool.swim")
                            .font(.system(size: 42))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    Text("Wake")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("A focused pool swimming tracker. Plan workouts, swim them with a guided interval clock, and watch your pace improve — all offline, no account.")
                        .font(.callout)
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)

                    SectionCard(title: "Why Wake", symbol: "sparkles") {
                        VStack(alignment: .leading, spacing: 10) {
                            bullet("All your swims live on your device — private and offline.")
                            bullet("One-time unlock, no subscription, no Apple Watch required.")
                            bullet("Pace per 100, SWOLF, and stroke breakdowns built for swimmers.")
                        }
                    }

                    Text("Version 1.0")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
