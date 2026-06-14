import SwiftUI

/// A short, honest about sheet.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 16)
                        .accessibilityHidden(true)

                    Text("Cobble")
                        .font(Theme.rounded(30, .bold)).foregroundStyle(Theme.ink)
                    Text("A calm, ad-free block puzzle. Drop pieces, clear lines, chase combos — no timer, no pressure.")
                        .font(Theme.rounded(16)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        row("hand.tap", "Tap a piece, then tap the board to place it.")
                        row("rectangle.split.3x3", "Fill rows and columns to clear them.")
                        row("flame", "Chain clears for combo multipliers.")
                        row("nosign", "No ads, no tracking, all on-device.")
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                    .padding(.horizontal, 4)

                    Text("Version 1.0")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
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

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text).font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
