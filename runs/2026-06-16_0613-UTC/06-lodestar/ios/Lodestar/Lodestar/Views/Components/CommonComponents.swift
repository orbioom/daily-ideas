import SwiftUI

/// A calm empty-state view used wherever data may be absent.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(19, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let ctaTitle, let ctaAction {
                Button(action: ctaAction) {
                    Text(ctaTitle)
                        .font(Theme.rounded(15, .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent.opacity(0.18)))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: 360)
        .padding(28)
        .accessibilityElement(children: .combine)
    }
}

/// A loading state with a small spinner and a calming line.
struct LoadingView: View {
    var message: String = "Computing the sky…"
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// A calm, recoverable error state.
struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("Something went quiet")
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Try again", action: retry)
                    .font(Theme.rounded(15, .semibold))
                    .tint(Theme.accent)
            }
        }
        .padding(28)
        .accessibilityElement(children: .combine)
    }
}

/// A section header in the Lodestar identity.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .textCase(.uppercase)
                .foregroundStyle(Theme.inkSoft)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small pill badge.
struct Pill: View {
    let text: String
    var color: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(Theme.rounded(12, .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.16)))
            .foregroundStyle(color)
    }
}

/// A success toast overlay.
struct SuccessToast: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(14, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Capsule().fill(Theme.good))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
