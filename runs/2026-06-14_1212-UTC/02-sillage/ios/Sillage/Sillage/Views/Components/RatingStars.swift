import SwiftUI

/// Read-only 0...5 star display.
struct RatingStars: View {
    let rating: Int
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(Theme.accent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) of 5 stars")
    }
}

/// Interactive 0...5 star picker bound to an Int.
struct StarPicker: View {
    @Binding var rating: Int
    var allowsZero: Bool = true
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    if allowsZero && rating == i {
                        rating = i - 1
                    } else {
                        rating = i
                    }
                    onChange?()
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                .accessibilityAddTraits(i <= rating ? .isSelected : [])
            }
        }
    }
}
