import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String)] = [
        ("tray.full.fill", "Track your whole library — owned, playing, beaten, dropped and wishlist."),
        ("play.circle.fill", "Log play sessions and watch progress fill toward each game's length."),
        ("dice.fill", "Spin “What to Play Next” to beat decision paralysis."),
        ("trophy.fill", "Set a yearly beaten-games goal and follow your pace and stats.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Quest")
                            .font(Theme.rounded(30, .heavy))
                            .foregroundStyle(Theme.text)
                        Text("Your private, native game backlog.")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.0) { feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: feature.0)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(feature.1)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))

                    Text("All your data stays on this device. No account, no feed, no tracking.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.textFaint)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
