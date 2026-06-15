import SwiftUI

/// A small section header used above grouped content on the calm scroll screens.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A coloured circular badge holding a tracker's SF Symbol — its visual identity throughout.
struct TrackerIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.18))
            Image(systemName: symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A compact tinted pill (strength / direction / confidence labels).
struct Pill: View {
    let text: String
    var color: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

/// A reusable labelled stat tile (value over caption).
struct StatTile: View {
    let value: String
    let caption: String
    var color: Color = Theme.ink

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(Theme.surfaceAlt)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption): \(value)")
    }
}
