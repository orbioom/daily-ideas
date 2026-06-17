import SwiftUI

/// The win/lose card shown when a game finishes. Shows the outcome, the answer on a
/// loss, quick lifetime stats, a Share button, and a primary action.
struct EndCardView: View {
    @Environment(\.colorScheme) private var scheme

    let vm: GameViewModel
    let highContrast: Bool
    let stats: StatsSummary
    /// Primary action title + handler (e.g. "Play Again" / "See Stats").
    let primaryTitle: String
    let onPrimary: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(LexTheme.secondaryText(scheme).opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)

            Image(systemName: vm.didWin ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(vm.didWin ? LexTheme.green : LexTheme.secondaryText(scheme))
                .accessibilityHidden(true)

            Text(vm.didWin ? "Solved!" : "So close")
                .font(LexTheme.display(26, weight: .bold))
                .foregroundStyle(LexTheme.primaryText(scheme))

            if vm.didWin {
                Text("You found it in \(vm.guessCountForResult) of \(vm.maxGuesses).")
                    .font(.subheadline)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            } else {
                VStack(spacing: 4) {
                    Text("The word was")
                        .font(.subheadline)
                        .foregroundStyle(LexTheme.secondaryText(scheme))
                    Text(vm.answer.uppercased())
                        .font(LexTheme.display(24, weight: .heavy))
                        .foregroundStyle(LexTheme.primaryText(scheme))
                        .tracking(2)
                }
            }

            // Quick stats row
            HStack(spacing: 0) {
                statCell("Played", "\(stats.played)")
                divider
                statCell("Win %", "\(stats.winPercent)")
                divider
                statCell("Streak", "\(stats.currentStreak)")
                divider
                statCell("Max", "\(stats.maxStreak)")
            }
            .padding(.vertical, 8)

            VStack(spacing: 10) {
                ShareLink(item: vm.shareText(highContrast: highContrast)) {
                    Label("Share result", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LexPrimaryButtonStyle())

                Button(primaryTitle) { onPrimary() }
                    .buttonStyle(LexSecondaryButtonStyle())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LexTheme.cardSurface(scheme))
        )
        .overlay(alignment: .topTrailing) {
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
                    .padding(12)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
    }

    private var divider: some View {
        Rectangle()
            .fill(LexTheme.hairline(scheme))
            .frame(width: 1, height: 34)
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(LexTheme.primaryText(scheme))
            Text(title)
                .font(.caption2)
                .foregroundStyle(LexTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
