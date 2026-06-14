import SwiftUI

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
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.font(.title3, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.font(.headline))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
                .accessibilityHint("Adds your first entry")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

// MARK: - Primary button style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.headline))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card container

struct CardContainer<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            )
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    /// 0...1
    let fraction: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 7
    var tint: Color = Theme.accent
    var label: String? = nil

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.separator, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let label {
                Text(label)
                    .font(Theme.font(.caption, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

// MARK: - Stat pill

struct StatPill: View {
    let symbol: String
    let value: String
    let caption: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.textPrimary)
            Text(caption)
                .font(Theme.font(.caption2))
                .foregroundStyle(Theme.textSecondary)
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

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Text(title)
                .font(Theme.font(.headline, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(Theme.font(.subheadline))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Loading shimmer row

struct LoadingRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
            .fill(Theme.surfaceAlt)
            .frame(height: 18)
            .opacity(pulse ? 0.5 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .accessibilityHidden(true)
    }
}
