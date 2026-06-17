import SwiftUI

/// A row of 1–3 stars used for level scoring.
struct StarRatingView: View {
    let stars: Int
    var max: Int = 3
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(i < stars ? Theme.star : Theme.inkSoft.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(stars) of \(max) stars")
    }
}
