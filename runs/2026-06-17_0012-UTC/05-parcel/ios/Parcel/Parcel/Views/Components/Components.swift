import SwiftUI

/// A circular readiness/progress ring with a centered percentage.
struct ReadinessRing: View {
    /// 0...1 progress.
    var progress: Double
    var size: CGFloat = 150
    var lineWidth: CGFloat = 14
    var label: String = "Ready"
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline(scheme), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [Theme.accent, Theme.gold, Theme.accent],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: clamped)
            VStack(spacing: 2) {
                Text("\(Int((clamped * 100).rounded()))%")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(Int((clamped * 100).rounded())) percent")
    }
}

/// A compact labeled statistic tile.
struct StatTile: View {
    var value: String
    var caption: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary(scheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(caption)")
    }
}

/// A labeled mastery progress bar (0...1).
struct MasteryBar: View {
    var value: Double
    var tint: Color = Theme.accent
    var height: CGFloat = 8
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline(scheme))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A calm empty-state block.
struct EmptyStateCard: View {
    var systemImage: String
    var title: String
    var message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

/// A section header with a serif title.
struct SectionTitle: View {
    var text: String
    var subtitle: String? = nil
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small "PRO" badge.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Theme.gold))
            .accessibilityLabel("Pro feature")
    }
}

/// A pill chip for a topic.
struct TopicChip: View {
    var topic: Topic
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: topic.systemImage)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(topic.shortTitle)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(topic.chipColor))
    }
}
