import SwiftUI

// MARK: - Section header

struct SectionTitle: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(HavenTheme.accent)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HavenTheme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quick action tile (Home)

struct QuickTile: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(HavenTheme.accentDeep)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(HavenTheme.primaryText(scheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .padding(16)
            .background(HavenTheme.card(scheme))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.05), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Pro badge / lock chip

struct ProChip: View {
    var body: some View {
        Text("Plus")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(HavenTheme.sosGradient)
            .clipShape(Capsule())
            .accessibilityLabel("Haven Plus feature")
    }
}

// MARK: - Intensity color helper

enum IntensityStyle {
    static func color(for value: Int) -> Color {
        switch value {
        case 0...3: return HavenTheme.calmGreen
        case 4...6: return HavenTheme.warmAmber
        default: return HavenTheme.softRose
        }
    }

    static func label(for value: Int) -> String {
        switch value {
        case 0...2: return "Gentle"
        case 3...4: return "Mild"
        case 5...6: return "Moderate"
        case 7...8: return "Strong"
        default: return "Intense"
        }
    }
}

// MARK: - Selectable chip

struct SelectableChip: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : HavenTheme.primaryText(scheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if isSelected {
                            AnyView(HavenTheme.sosGradient)
                        } else {
                            AnyView(HavenTheme.subtleFill(scheme))
                        }
                    }
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
