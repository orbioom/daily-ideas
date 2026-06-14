import SwiftUI

/// A recipe summary card showing match %, missing chips, and metadata.
struct RecipeCard: View {
    let result: MatchResult

    private var recipe: Recipe { result.recipe }

    private var statusTint: Color {
        if result.isMakeable { return Theme.good }
        if result.oneAway { return Theme.warn }
        return Theme.accent
    }

    private var statusText: String {
        if result.isMakeable { return "Ready to cook" }
        if result.oneAway { return "1 ingredient away" }
        return "\(result.missing.count) ingredients away"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(Theme.serif(19, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Pill(text: recipe.cuisine.rawValue, systemImage: recipe.cuisine.symbol, tint: recipe.cuisine.hue)
                        Pill(text: recipe.timeLabel, systemImage: "clock", tint: Theme.inkSoft)
                    }
                }
                Spacer(minLength: 4)
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }

            HStack(spacing: 8) {
                MatchBar(percent: result.matchPercent, tint: statusTint)
                Text("\(result.matchPercentInt)%")
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(statusTint)
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                Image(systemName: result.isMakeable ? "checkmark.circle.fill" : "cart")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusTint)
                    .accessibilityHidden(true)
                Text(statusText)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(statusTint)
            }

            if !result.isMakeable {
                missingChips
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(result.matchPercentInt) percent match, \(statusText)")
    }

    private var missingChips: some View {
        let names = result.missing.prefix(4).map { $0.name }
        let extra = max(0, result.missing.count - 4)
        return HStack(spacing: 6) {
            ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.bad)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.bad.opacity(0.12)))
                    .lineLimit(1)
            }
            if extra > 0 {
                Text("+\(extra)")
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
