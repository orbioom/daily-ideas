import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Tangle")
                        .font(Theme.rounded(28, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("A calm, ad-free word-find crossword. Swipe letters on the wheel to fill the grid, collect bonus words, and unwind — entirely offline.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        aboutRow("hand.tap.fill", "Swipe or tap the wheel to spell words.")
                        aboutRow("square.grid.3x3.fill", "Fill every word in the interlocking grid.")
                        aboutRow("sparkles", "Extra valid words become bonus treasures.")
                        aboutRow("calendar", "A fresh daily puzzle keeps your streak alive.")
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)))

                    Text("Version 1.0 — No ads, no timers, no nonsense.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentDeep)
                }
            }
        }
    }

    private func aboutRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
