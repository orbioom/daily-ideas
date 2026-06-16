import SwiftUI

/// Calm reusable empty state with icon, message, and optional CTA.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.serif(.title3))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.rounded(15, .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}
