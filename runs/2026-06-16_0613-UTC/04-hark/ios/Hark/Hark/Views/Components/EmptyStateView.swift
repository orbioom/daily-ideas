import SwiftUI

/// Calm empty state: icon + line + optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let ctaTitle, let ctaAction {
                PrimaryButton(title: ctaTitle, action: ctaAction)
                    .padding(.top, 4)
                    .frame(maxWidth: 280)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Lightweight success toast overlay.
struct SuccessToast: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(Theme.good)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}
