import SwiftUI

/// A circular readiness gauge showing a 0...1 fraction as a federal-blue ring.
struct ReadinessRing: View {
    let fraction: Double
    var size: CGFloat = 140
    var lineWidth: CGFloat = 14
    var caption: String = "Ready"

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(1, max(0, fraction)) }
    private var percent: Int { Int((clamped * 100).rounded()) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline(scheme), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.7), Theme.gold],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: clamped)
            VStack(spacing: 2) {
                Text("\(percent)%")
                    .font(Theme.serifTitle(size * 0.26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .monospacedDigit()
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .textCase(.uppercase)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption)")
        .accessibilityValue("\(percent) percent")
    }
}

/// Three small dots indicating mastery level 0...3.
struct MasteryDots: View {
    let level: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < level ? fillColor : Theme.hairline(scheme))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mastery")
        .accessibilityValue(masteryDescription)
    }

    private var fillColor: Color {
        switch level {
        case 3: return Theme.success(scheme)
        case 2: return Theme.gold
        default: return Theme.accent
        }
    }

    private var masteryDescription: String {
        switch level {
        case 0: return "Not started"
        case 1: return "Learning"
        case 2: return "Familiar"
        default: return "Strong"
        }
    }
}

/// A small "PRO" pill.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(Theme.gold))
            .accessibilityLabel("Pro feature")
    }
}

/// A category chip used as a filter.
struct CategoryChip: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? .white : Theme.textPrimary(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Theme.accent : Theme.cardSecondary(scheme))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A reusable empty-state block.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 4)
                    .frame(maxWidth: 240)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// A section header in the serif display face.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
