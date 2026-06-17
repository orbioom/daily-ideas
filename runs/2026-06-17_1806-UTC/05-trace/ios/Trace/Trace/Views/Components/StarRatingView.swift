import SwiftUI

/// Shows up to `maxStars` stars; `count` filled. Optionally animates the fill.
struct StarRatingView: View {
    let count: Int
    var maxStars: Int = 3
    var size: CGFloat = 22
    var animated: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < count ? Theme.star : Theme.hairline)
                    .scaleEffect(scale(for: index))
                    .animation(
                        (animated && !reduceMotion)
                            ? .spring(response: 0.4, dampingFraction: 0.5).delay(Double(index) * 0.12)
                            : nil,
                        value: count
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatters.starsPhrase(count))
    }

    private func scale(for index: Int) -> CGFloat {
        guard animated, !reduceMotion else { return 1 }
        return index < count ? 1 : 0.85
    }
}
