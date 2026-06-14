import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Across")
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("A daily mini crossword")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text("Across is a clean, ad-free daily mini crossword. A fresh puzzle every day, a generous archive of Minis and Midis, and nothing in your way — no feed, no clutter, no subscription.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Tap a square to select it, tap again to switch between Across and Down. Use the clue bar arrows to move between answers, and the Check / Reveal menu when you're stuck. Your progress and timer are saved automatically.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Made by Orbioom")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Built with SwiftUI, SwiftData, and Swift Charts for iOS 17. Everything stays on your device.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
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
