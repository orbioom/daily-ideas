import SwiftUI

// MARK: - Progress ring

struct ProgressRing: View {
    var fraction: Double
    var lineWidth: CGFloat = 10
    var tint: Color = Theme.accent
    var track: Color = Theme.hairline
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: fraction)
        }
    }
}

// MARK: - Pill / chip

struct CategoryChip: View {
    var category: GoalCategory
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.systemImage)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
            if !compact {
                Text(category.label)
                    .font(Theme.rounded(12, .semibold))
            }
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            Capsule().fill(category.color.opacity(0.14))
        )
        .accessibilityLabel("Category: \(category.label)")
    }
}

// MARK: - Pebble + energy badges

struct PebbleBadge: View {
    var count: Int
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.grid.2x2.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.warn)
            Text("\(count)")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) pebbles")
    }
}

// MARK: - Toast (reward feedback)

struct RewardToast: Equatable, Identifiable {
    let id = UUID()
    var pebbles: Int
    var energy: Int
    var message: String?
}

struct RewardToastView: View {
    var toast: RewardToast
    var body: some View {
        HStack(spacing: 12) {
            if let message = toast.message {
                Text(message)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
            } else {
                Label("+\(toast.pebbles)", systemImage: "circle.grid.2x2.fill")
                    .foregroundStyle(Theme.warn)
                Label("+\(toast.energy)", systemImage: "bolt.fill")
                    .foregroundStyle(Theme.good)
            }
        }
        .font(Theme.rounded(14, .semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(Theme.surface)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        )
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
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

// MARK: - Empty state

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(19, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(WrenPrimaryButtonStyle())
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Buttons

struct WrenPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(16, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(isEnabled ? Theme.accent : Theme.inkFaint)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct WrenSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(16, .semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(Theme.accentSoft)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Stat tile

struct StatTile: View {
    var value: String
    var label: String
    var systemImage: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card(Theme.surfaceAlt)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
