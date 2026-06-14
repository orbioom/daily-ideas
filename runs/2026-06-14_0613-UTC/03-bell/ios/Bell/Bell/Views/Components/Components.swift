import SwiftUI

// MARK: - Card container
struct Card<Content: View>: View {
    var padding: CGFloat = Theme.spacing
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            )
    }
}

// MARK: - Primary button
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: fill ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, fill ? 0 : 24)
            .background(Theme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat tile
struct StatTile: View {
    let value: String
    let label: String
    var symbol: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacing)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Progress ring
struct ProgressRing: View {
    let progress: Double          // 0...1
    var lineWidth: CGFloat = 12
    var tint: Color = Theme.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.separator, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.7), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Empty state
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.serif(22, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, fill: false, action: action)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Pro lock badge
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(Theme.rounded(10, .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Theme.accent.opacity(0.16))
            .foregroundStyle(Theme.accentDeep)
            .clipShape(Capsule())
            .accessibilityLabel("Pro feature")
    }
}
