import SwiftUI

/// A 0...10 rating control rendered as ten tappable pips. Tapping the current
/// max again clears the rating (0 = unrated). Read-only mode just displays.
struct RatingView: View {
    @Binding var rating: Int
    var editable: Bool = true
    var onChange: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...10, id: \.self) { value in
                pip(for: value)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Personal rating")
        .accessibilityValue(rating == 0 ? "Unrated" : "\(rating) out of 10")
        .accessibilityAdjustableAction { direction in
            guard editable else { return }
            switch direction {
            case .increment: set(min(10, rating + 1))
            case .decrement: set(max(0, rating - 1))
            @unknown default: break
            }
        }
    }

    @ViewBuilder
    private func pip(for value: Int) -> some View {
        let filled = value <= rating
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        Group {
            if editable {
                Button {
                    // Tapping the current top pip clears the rating.
                    set(value == rating ? 0 : value)
                } label: { pipBody(filled: filled, shape: shape) }
                .buttonStyle(.plain)
            } else {
                pipBody(filled: filled, shape: shape)
            }
        }
        .accessibilityHidden(true)
    }

    private func pipBody(filled: Bool, shape: RoundedRectangle) -> some View {
        shape
            .fill(filled ? Theme.accent : Theme.stroke)
            .frame(width: 16, height: 22)
            .overlay(shape.strokeBorder(filled ? Theme.accentDeep : .clear, lineWidth: 1))
    }

    private func set(_ value: Int) {
        rating = value
        onChange?(value)
    }
}

/// Read-only compact rating badge (e.g. on cards).
struct RatingBadge: View {
    let rating: Int

    var body: some View {
        if rating > 0 {
            HStack(spacing: 2) {
                Image(systemName: "star.fill").font(.system(size: 9, weight: .bold))
                Text("\(rating)").font(Theme.mono(11, .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.45), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rated \(rating) out of 10")
        }
    }
}
