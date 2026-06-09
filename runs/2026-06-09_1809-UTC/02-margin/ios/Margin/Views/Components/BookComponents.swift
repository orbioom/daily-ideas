import SwiftUI

/// An editable or read-only 5-star rating control.
struct StarRating: View {
    @Binding var rating: Int
    var editable: Bool = true
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Brand.warn : Brand.text3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard editable else { return }
                        Haptics.tap()
                        // Tapping the current single star clears it back to zero.
                        rating = (rating == star) ? star - 1 : star
                    }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(rating == 0 ? "Not rated" : "\(rating) of 5 stars")
        .accessibilityAdjustableAction { direction in
            guard editable else { return }
            switch direction {
            case .increment: rating = min(5, rating + 1)
            case .decrement: rating = max(0, rating - 1)
            default: break
            }
        }
    }
}

/// A read-only compact star row for cards and lists.
struct StarRow: View {
    let rating: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Brand.warn : Brand.text3.opacity(0.5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating == 0 ? "Not rated" : "\(rating) of 5 stars")
    }
}

/// A small book "spine" tile that stands in for a cover, colored deterministically.
struct BookSpine: View {
    let book: Book
    var width: CGFloat = 44
    var height: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: book.spineColor),
                             Color(hex: book.spineColor).opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 3)
                    .padding(.vertical, 6)
                    .padding(.leading, 4)
            }
            .overlay {
                Image(systemName: "book.closed")
                    .font(.system(size: width * 0.34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(width: width, height: height)
            .shadow(color: Brand.cardShadow, radius: 4, x: 0, y: 2)
            .accessibilityHidden(true)
    }
}

/// A thin progress bar with an accessible label, used on book cards.
struct ProgressBar: View {
    let fraction: Double      // 0…1
    var tint: Color = Brand.magic
    var height: CGFloat = 8
    var label: String = "Reading progress"

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline)
                Capsule().fill(tint.opacity(0.9))
                    .frame(width: geo.size.width * CGFloat(clamped))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Format.percent(clamped))
    }
}

/// A small status pill (Reading / Finished / …).
struct StatusPill: View {
    let status: ReadingStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: 10, weight: .semibold))
                .accessibilityHidden(true)
            Text(status.label)
                .font(Brand.mono(11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(status.tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.label)")
    }
}
