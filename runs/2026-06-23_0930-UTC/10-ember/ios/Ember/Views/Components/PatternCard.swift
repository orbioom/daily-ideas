import SwiftUI

/// A tappable card summarizing a breathing technique.
struct PatternCard: View {
    let pattern: BreathPattern
    var isFavorite: Bool
    var onToggleFavorite: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(pattern.style.accent.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: pattern.style.systemImage)
                    .font(.title3)
                    .foregroundStyle(pattern.style.accent)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(pattern.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(pattern.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Text(pattern.rhythmLabel)
                    .font(.caption.monospaced())
                    .foregroundStyle(pattern.style.accent)
            }
            Spacer(minLength: 0)

            if let onToggleFavorite {
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? Theme.bad : Theme.textSecondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .emberCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.name), \(pattern.subtitle), rhythm \(pattern.rhythmLabel)")
    }
}
