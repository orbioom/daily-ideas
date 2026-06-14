import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Relish")
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Your private restaurant ranker")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Relish keeps an ordered list of every place you've been. Instead of arbitrary stars, you rank by comparing — pick how a place felt, answer a few quick \"which was better?\" matchups, and Relish slots it into your personal order, then derives a 0–10 score from where it lands.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Everything stays on your device. No account, no feed, no cloud.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by Orbioom")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Built with SwiftUI, SwiftData, and Swift Charts for iOS 17.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(22)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
