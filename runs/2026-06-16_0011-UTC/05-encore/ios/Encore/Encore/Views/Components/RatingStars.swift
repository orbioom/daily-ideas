import SwiftUI

/// Read-only half-star rating display (0...5 in 0.5 steps).
struct RatingStarsDisplay: View {
    let rating: Double
    var size: CGFloat = 13
    var tint: Color = Theme.gold

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: symbol(for: i))
                    .font(.system(size: size))
                    .foregroundStyle(tint)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "%.1f of 5 stars", clamped))
    }

    private var clamped: Double { min(max(rating, 0), 5) }

    private func symbol(for index: Int) -> String {
        let threshold = Double(index)
        if clamped >= threshold + 1 { return "star.fill" }
        if clamped >= threshold + 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Interactive half-star rating editor. Binding may be nil (un-rated); tapping sets it.
struct RatingStarsEditor: View {
    @Binding var rating: Double?
    var hapticsEnabled: Bool
    var size: CGFloat = 30

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                let value = Double(i)
                Button {
                    // Tapping the current full value drops to its half; otherwise sets full.
                    if rating == value {
                        set(value - 0.5)
                    } else {
                        set(value)
                    }
                } label: {
                    Image(systemName: symbol(for: i))
                        .font(.system(size: size))
                        .foregroundStyle(Theme.gold)
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
            if rating != nil {
                Button {
                    rating = nil
                    Haptics.tap(enabled: hapticsEnabled)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: size * 0.6))
                        .foregroundStyle(Theme.inkFaint)
                }
                .accessibilityLabel("Clear rating")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(rating.map { String(format: "%.1f of 5 stars", $0) } ?? "Not rated")
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment: set(min(current + 0.5, 5))
            case .decrement: set(max(current - 0.5, 0))
            @unknown default: break
            }
        }
    }

    private func set(_ value: Double) {
        rating = min(max(value, 0), 5)
        Haptics.selection(enabled: hapticsEnabled)
    }

    private func symbol(for index: Int) -> String {
        let current = rating ?? 0
        let threshold = Double(index - 1)
        if current >= threshold + 1 { return "star.fill" }
        if current >= threshold + 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
