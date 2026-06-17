import SwiftUI

/// A row summarizing a cook in a list.
struct CookRow: View {
    @Environment(AppSettings.self) private var settings
    let cook: Cook

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: cook.protein.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(cook.protein.hue)
                .frame(width: 34, height: 34)
                .background(Circle().fill(cook.protein.hue.opacity(0.15)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(cook.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(cook.cut) · \(settings.weight(cook.weightKg)) · \(cook.method.label)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Pill(text: cook.status.label, systemImage: cook.status.symbol, tint: cook.status.hue)
                if cook.status == .done, let rating = cook.clampedRating {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.ember)
                        }
                    }
                    .accessibilityLabel("\(rating) of 5 stars")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
