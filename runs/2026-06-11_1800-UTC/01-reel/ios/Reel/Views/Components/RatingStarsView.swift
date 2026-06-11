import SwiftUI

struct RatingStarsView: View {
    @Binding var rating: Double
    let maxRating: Int = 5
    var editable: Bool = true
    var starSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: starIcon(for: star))
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= Int(rating.rounded()) ? Theme.gold : Theme.silver.opacity(0.4))
                    .onTapGesture {
                        guard editable else { return }
                        withAnimation(.spring(response: 0.2)) {
                            if rating == Double(star) {
                                rating = 0
                            } else {
                                rating = Double(star)
                            }
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating: \(Int(rating)) out of \(maxRating) stars")
        .accessibilityValue("\(Int(rating))")
        .accessibilityAdjustableAction { dir in
            guard editable else { return }
            switch dir {
            case .increment: rating = min(Double(maxRating), rating + 1)
            case .decrement: rating = max(0, rating - 1)
            @unknown default: break
            }
        }
    }

    private func starIcon(for star: Int) -> String {
        star <= Int(rating.rounded()) ? "star.fill" : "star"
    }
}
