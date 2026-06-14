import SwiftUI

/// A horizontal progress bar with an accessible value.
struct ProgressBar: View {
    let fraction: Double      // 0...1
    var color: Color = Theme.accent
    var height: CGFloat = 8

    private var clamped: Double { min(1, max(0, fraction)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.stroke)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

/// A friendly empty state used across screens.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.rounded(15, .semibold))
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// A titled rounded card container.
struct SectionCard<Content: View>: View {
    let title: String?
    var systemImage: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Label {
                    Text(title).font(Theme.rounded(15, .bold))
                } icon: {
                    if let systemImage {
                        Image(systemName: systemImage).foregroundStyle(Theme.accent)
                    }
                }
                .foregroundStyle(Theme.text)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }
}

/// A labelled stat tile.
struct StatTile: View {
    let value: String
    let label: String
    var color: Color = Theme.accent

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(22, .heavy))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
