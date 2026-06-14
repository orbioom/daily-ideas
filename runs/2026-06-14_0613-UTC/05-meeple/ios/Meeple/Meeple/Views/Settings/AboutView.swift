import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Theme.accent.opacity(0.16)).frame(width: 96, height: 96)
                            Image(systemName: "die.face.5.fill").font(.system(size: 44)).foregroundStyle(Theme.accent)
                        }
                        .padding(.top, 12)
                        .accessibilityHidden(true)

                        Text("Meeple").font(Theme.serif(30, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("Your board game collection & play logger.")
                            .font(Theme.rounded(15)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        CardSection("What it does") {
                            VStack(alignment: .leading, spacing: 8) {
                                aboutRow("square.grid.2x2.fill", "Catalog every game with generated covers, ratings, weight and status.")
                                aboutRow("dice.fill", "Log plays — players, scores and winners — with snapshotted names.")
                                aboutRow("chart.bar.xaxis", "Rich stats: most-played, win rates, plays-per-month and your H-index.")
                                aboutRow("sparkles", "“What should we play?” picker matches games to tonight's table.")
                            }
                        }

                        CardSection("Credits") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Built with SwiftUI, SwiftData and Swift Charts for iOS 17.")
                                    .font(Theme.rounded(14)).foregroundStyle(Theme.textPrimary)
                                Text("Game data is sample content for demonstration.")
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
                                Text("An Orbioom studio app · Version 1.0")
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func aboutRow(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 24)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
