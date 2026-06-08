import SwiftUI

/// Displays or edits a 1–5 star quality rating.
struct StarRating: View {
    @Binding var rating: Int
    var interactive: Bool = true
    var starSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= rating ? Brand.warn : Brand.hairline)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        Haptics.selection()
                        rating = star
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    .accessibilityAddTraits(star == rating ? .isSelected : [])
                    .accessibilityHint(interactive ? "Double tap to set quality to \(star)" : "")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep quality")
        .accessibilityValue("\(rating) out of 5 stars")
    }
}

/// Read-only compact star row used in list cells.
struct StarRatingDisplay: View {
    let rating: Int
    var starSize: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= rating ? Brand.warn : Brand.hairline)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quality")
        .accessibilityValue("\(rating) out of 5")
    }
}
