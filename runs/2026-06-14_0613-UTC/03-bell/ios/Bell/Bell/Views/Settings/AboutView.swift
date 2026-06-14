import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Bell")
                        .font(Theme.serif(34, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("An unguided meditation timer with real bells.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our promise")
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        promise("No subscriptions", "Bell Pro is one calm purchase, forever.")
                        promise("No ads", "Ever. Your sit is sacred.")
                        promise("No guidance", "Just you, your breath, and a gentle bell.")
                        promise("Private", "Your sessions live only on your device.")
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works")
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Bells are synthesized live on your device — additive sine partials shaped by an exponential decay, rendered straight into the audio engine. Nothing is streamed; nothing is recorded.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Text("Made with care by Orbioom.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 4)
            }
            .padding(Theme.spacing)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func promise(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
                .padding(.top, 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.textPrimary)
                Text(body).font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
