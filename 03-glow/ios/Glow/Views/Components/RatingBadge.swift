import SwiftUI

struct RatingBadge: View {
    let rating: Int
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .system(.caption, design: .rounded, weight: .bold)
            case .medium: return .system(.callout, design: .rounded, weight: .bold)
            case .large: return .system(.title, design: .rounded, weight: .bold)
            }
        }

        var dimension: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 40
            case .large: return 72
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return .system(size: 9, weight: .semibold, design: .rounded)
            case .medium: return .system(size: 11, weight: .semibold, design: .rounded)
            case .large: return .system(size: 15, weight: .semibold, design: .rounded)
            }
        }
    }

    private var color: Color { GlowTheme.ratingColor(rating) }
    private var label: String { GlowTheme.ratingLabel(rating) }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(rating)")
                .font(size.font)
                .foregroundStyle(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: size == .large ? 20 : 10))

            if size == .large {
                Text(label)
                    .font(size.labelFont)
                    .foregroundStyle(color)
            }
        }
    }
}

struct RatingBadgeInline: View {
    let rating: Int

    private var color: Color { GlowTheme.ratingColor(rating) }
    private var label: String { GlowTheme.ratingLabel(rating) }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(rating)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(1...5, id: \.self) { r in
            RatingBadge(rating: r, size: .large)
        }
    }
    .padding()
}
