import SwiftUI

struct StatusPill: View {
    let status: GameStatus
    var compact: Bool = false
    var body: some View {
        Label(status.label, systemImage: status.symbol)
            .labelStyle(.titleAndIcon)
            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .padding(.horizontal, compact ? 7 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(status.tint.opacity(0.18), in: Capsule())
            .foregroundStyle(status.tint)
            .accessibilityLabel(status.label)
    }
}

struct CoverSwatch: View {
    let game: Game
    var size: CGFloat = 56
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(game.coverGradient)
            .frame(width: size, height: size * 1.18)
            .overlay(
                Text(game.initials)
                    .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

/// Half-star rating control. `ratingHalf` is 0...10 (steps of half a star).
struct StarRating: View {
    @Binding var ratingHalf: Int
    var interactive: Bool = true
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                star(at: star)
            }
            if interactive && ratingHalf > 0 {
                Button {
                    Haptics.tap(); ratingHalf = 0
                } label: { Image(systemName: "xmark.circle").font(.footnote) }
                .foregroundStyle(Theme.textSecondary)
                .accessibilityLabel("Clear rating")
            }
        }
        .accessibilityElement(children: interactive ? .contain : .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(ratingHalf == 0 ? "Unrated" : String(format: "%.1f of 5", Double(ratingHalf) / 2))
    }

    @ViewBuilder private func star(at index: Int) -> some View {
        let full = ratingHalf >= index * 2
        let half = !full && ratingHalf == index * 2 - 1
        let symbol = full ? "star.fill" : (half ? "star.leadinghalf.filled" : "star")
        Image(systemName: symbol)
            .font(.system(size: size))
            .foregroundStyle(full || half ? Theme.gold : Theme.track)
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard interactive else { return }
                Haptics.tap()
                // Tap left half → half star, right half → full star.
                ratingHalf = location.x < size / 2 ? index * 2 - 1 : index * 2
            }
    }
}

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent).tint(Theme.accent).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity).padding(28)
    }
}

struct MiniStat: View {
    var value: String
    var label: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
