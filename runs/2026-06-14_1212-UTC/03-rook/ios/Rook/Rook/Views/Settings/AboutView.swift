import SwiftUI

/// About sheet describing Rook and its design.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.accentSoft)
                            .frame(width: 96, height: 96)
                        Text("\u{265C}")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 10)
                    .accessibilityHidden(true)

                    Text("Rook")
                        .font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                    Text("A beautiful, offline chess trainer")
                        .font(Theme.rounded(16)).foregroundStyle(Theme.inkSoft)

                    infoCard(title: "A real engine",
                             body: "Rook plays with a self-contained engine: full legal move generation, castling, en passant, and promotion, plus a negamax search with alpha-beta pruning. No internet required.")
                    infoCard(title: "Puzzles you can trust",
                             body: "Mate-in-one puzzles are validated by the engine itself — your move is correct only if it leaves your opponent checkmated. That makes them robust and fair.")
                    infoCard(title: "Private by design",
                             body: "Your games, puzzle results, and streaks live only on this device. No account, no tracking, no feed.")

                    Text("Made for players who just want to sit down and play.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
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

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
            Text(body).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }
}
